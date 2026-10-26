import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../data/services.dart';
import 'duo.dart';
import 'widgets.dart';

/// Interactive story player — Duolingo Stories style.
/// Beats: narrate / say (bubble + TTS + tappable hanzi) / check (✓✗) /
/// blank (fill phrase) / pick (tap the word).
class StoryScreen extends StatefulWidget {
  final AppState state;
  final ContentRepository content;
  final TtsService tts;
  final SfxService sfx;
  final Story story;
  const StoryScreen({super.key, required this.state, required this.content, required this.tts, required this.sfx, required this.story});

  static void open(BuildContext context, {required AppState state, required ContentRepository content, required TtsService tts, required SfxService sfx, required String topicOrId}) {
    final s = content.storyFor(topicOrId);
    if (s == null) {
      duoToast(context, 'No story for this topic yet');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => StoryScreen(state: state, content: content, tts: tts, sfx: sfx, story: s),
    ));
  }

  @override
  State<StoryScreen> createState() => StoryScreenState();
}

class StoryScreenState extends State<StoryScreen> {
  final _scroll = ScrollController();
  final List<Widget> _shown = [];
  int _idx = 0;
  int _right = 0, _wrong = 0;
  bool _busy = false;
  bool _finished = false;
  String _bandMsg = '';
  bool _bandOk = true;
  late DateTime _t0;

  Story get s => widget.story;
  StoryBeat? get beat => _idx < s.beats.length ? s.beats[_idx] : null;

  @override
  void initState() {
    super.initState();
    _t0 = DateTime.now();
    _emit(noSet: true); // first beat before first build — no setState needed
  }

  Color get _accent {
    try {
      return Color(int.parse(s.color.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return Duo.green;
    }
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @visibleForTesting
  int get shownCount => _shown.length;
  @visibleForTesting
  int get beatIdx => _idx;

  void _emit({bool noSet = false}) {
    final b = beat;
    if (b == null) {
      if (noSet) { _idx = s.beats.length; return; } // _finish() on first LANJUT
      _finish();
      return;
    }
    switch (b.t) {
      case 'narrate':
        _shown.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(b.en, style: duoFont(size: 15, weight: FontWeight.w600, color: Duo.textLight, height: 1.5)
              .copyWith(fontStyle: FontStyle.italic)),
        ));
        _busy = false;
        break;
      case 'say':
        _shown.add(_sayLine(b));
        widget.tts.speak(b.hz);
        _busy = false;
        break;
      case 'check':
        _shown.add(_checkCard(b));
        _busy = true;
        break;
      case 'blank':
        _shown.add(_blankCard(b));
        _busy = true;
        break;
      case 'pick':
        _shown.add(_pickCard(b));
        _busy = true;
        break;
      default:
        _idx++;
        _emit(noSet: noSet);
        return;
    }
    if (!noSet) setState(() {});
    _scrollEnd();
  }

  // ---------- beats ----------
  Widget _sayLine(StoryBeat b) {
    final c = s.castOf(b.who);
    final right = b.who == 'lin';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: right ? TextDirection.rtl : TextDirection.ltr,
        children: [
          CircleAvatar(radius: 21, backgroundColor: _accent.withValues(alpha: .9), child: Text(c.emoji, style: const TextStyle(fontSize: 20))),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: right ? Duo.blueLight.withValues(alpha: dark ? .12 : 1) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(right ? 16 : 4), bottomRight: Radius.circular(right ? 4 : 16),
                ),
                border: Border.all(color: Theme.of(context).dividerColor, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.name, style: duoFont(size: 11, weight: FontWeight.w900, color: Duo.textLight)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => widget.tts.speak(b.hz),
                    child: const Icon(Icons.volume_up_rounded, size: 18, color: Duo.blue),
                  ),
                ]),
                const SizedBox(height: 2),
                HanziText(b.hz, fontSize: 18, weight: FontWeight.w800),
                Text(b.py, style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.blue)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qCard(String title, Widget body) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: duoFont(size: 15, weight: FontWeight.w900)),
        const SizedBox(height: 10),
        body,
      ]),
    );
  }

  Widget _opt(String label, {String? sub, required bool ok, required VoidCallback onTap, bool? result}) {
    Color border = Theme.of(context).dividerColor;
    Color fg = Theme.of(context).textTheme.bodyLarge?.color ?? Duo.text;
    if (result == true) { border = Duo.green; fg = Duo.green; }
    if (result == false) { border = Duo.rose; fg = Duo.rose; }
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: result == true ? Duo.greenLight.withValues(alpha: .35) : result == false ? Duo.roseLight.withValues(alpha: .3) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              top: BorderSide(color: border, width: 2), left: BorderSide(color: border, width: 2),
              right: BorderSide(color: border, width: 2), bottom: BorderSide(color: border, width: 4),
            ),
          ),
          child: Column(children: [
            Text(label, textAlign: TextAlign.center, style: duoFont(size: 15, weight: FontWeight.w800, color: fg)),
            if (sub != null) Text(sub, textAlign: TextAlign.center, style: duoFont(size: 11, weight: FontWeight.w600, color: Duo.textLight)),
          ]),
        ),
      ),
    );
  }

  void _band(String msg, bool ok) => setState(() { _bandMsg = msg; _bandOk = ok; });

  Widget _checkCard(StoryBeat b) {
    final key = 'check-$_idx';
    return _StatefulBeat(key: ValueKey(key), builder: (ctx, setB) {
      final picked = <int, bool?>{};
      return _qCard('True or false?', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(b.en, style: duoFont(size: 15, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          _opt('✓ True', ok: true, result: picked[1], onTap: () => _answerCheck(b, true, picked, setB)),
          const SizedBox(width: 10),
          _opt('✗ False', ok: false, result: picked[0], onTap: () => _answerCheck(b, false, picked, setB)),
        ]),
      ]));
    });
  }

  void _answerCheck(StoryBeat b, bool userAns, Map<int, bool?> picked, void Function(VoidCallback) setB) {
    final correct = userAns == b.ans;
    if (correct) {
      setB(() { picked[userAns ? 1 : 0] = true; picked[userAns ? 0 : 1] = null; });
      _right++; _band('Nice! Exactly right', true);
      widget.sfx.play('correct.wav');
      setState(() => _busy = false);
    } else {
      setB(() { picked[userAns ? 1 : 0] = false; });
      _wrong++; _band('Not quite — try again', false);
      widget.sfx.play('incorrect.wav');
    }
  }

  Widget _blankCard(StoryBeat b) {
    final c = s.castOf(b.who);
    return _StatefulBeat(key: ValueKey('blank-$_idx'), builder: (ctx, setB) {
      final picked = <int, bool>{};
      var locked = false;
      return _qCard('Complete ${c.name}\u2019s line', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(b.hz, style: duoFont(size: 19, weight: FontWeight.w800, height: 1.5)),
        Text(b.py, style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.blue)),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < b.opts.length; i++) ...[
            _opt(b.opts[i].$1, sub: b.opts[i].$2, ok: i == b.ansIdx, result: picked[i],
              onTap: locked ? () {} : () => _answerBlank(b, i, picked, setB, () => locked = true)),
            if (i < b.opts.length - 1) const SizedBox(width: 8),
          ],
        ]),
      ]));
    });
  }

  void _answerBlank(StoryBeat b, int i, Map<int, bool> picked, void Function(VoidCallback) setB, VoidCallback lock) {
    if (i == b.ansIdx) {
      lock();
      setB(() { picked[i] = true; });
      _right++; _band('Nice!', true);
      widget.sfx.play('correct.wav');
      setState(() => _busy = false);
      // show the completed line as a bubble
      final full = b.hz.replaceAll('___', b.opts[i].$1);
      final fp = b.py.replaceAll('___', b.opts[i].$2);
      _shown.add(_sayLine(StoryBeat(t: 'say', who: b.who, hz: full, py: fp)));
      widget.tts.speak(full);
      _scrollEnd();
    } else {
      setB(() { picked[i] = false; });
      _wrong++; _band('Not quite — try again', false);
      widget.sfx.play('incorrect.wav');
    }
  }

  Widget _pickCard(StoryBeat b) {
    final segs = _segPick(b.hz);
    return _StatefulBeat(key: ValueKey('pick-$_idx'), builder: (ctx, setB) {
      final marks = <int, bool>{};
      return _qCard(b.en, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(children: [
          for (var i = 0; i < segs.length; i++)
            GestureDetector(
              onTap: () => _answerPick(b, segs[i], i, marks, setB),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: marks[i] == true ? Duo.green : marks[i] == false ? Duo.rose : Theme.of(context).dividerColor, width: 2),
                  color: marks[i] == true ? Duo.greenLight.withValues(alpha: .4) : null,
                ),
                child: Text(segs[i], style: duoFont(size: 20, weight: FontWeight.w800, color: marks[i] == true ? Duo.green : marks[i] == false ? Duo.rose : null)),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        Text(b.py, style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.blue)),
      ]));
    });
  }

  List<String> _segPick(String hz) {
    final words = widget.content.vocab.map((v) => v.hanzi).where((w) => w.isNotEmpty).toList()
      ..sort((a, b) => b.length - a.length);
    final out = <String>[];
    var i = 0;
    while (i < hz.length) {
      String? m;
      for (final w in words) {
        if (hz.startsWith(w, i)) { m = w; break; }
      }
      out.add(m ?? hz[i]);
      i += (m ?? hz[i]).length;
    }
    return out;
  }

  void _answerPick(StoryBeat b, String seg, int i, Map<int, bool> marks, void Function(VoidCallback) setB) {
    if (seg == b.target) {
      setB(() { marks[i] = true; });
      _right++; _band('Correct!', true);
      widget.sfx.play('correct.wav');
      setState(() => _busy = false);
    } else {
      setB(() { marks[i] = false; });
      _wrong++; _band('Not that one — try again', false);
      widget.sfx.play('incorrect.wav');
    }
  }

  // ---------- flow ----------
  void _next() {
    if (_busy) return;
    setState(() { _idx++; _bandMsg = ''; });
    _emit();
  }

  void _finish() {
    final mins = ((DateTime.now().difference(_t0).inSeconds) / 60).ceil().clamp(1, 99);
    final acc = _right + _wrong == 0 ? 100 : (_right / (_right + _wrong) * 100).round();
    setState(() {
      _finished = true;
      _shown.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          SvgPicture.asset('assets/svg/finish.svg', width: 140, height: 140),
          const SizedBox(height: 12),
          Text('Story complete!', style: duoFont(size: 22, weight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(children: [
            _doneCard('TOTAL XP', '+20', Duo.amber),
            const SizedBox(width: 8),
            _doneCard('ACCURACY', '$acc%', Duo.blue),
            const SizedBox(width: 8),
            _doneCard('TIME', '${mins}m', Duo.rose),
          ]),
        ]),
      ));
    });
    _scrollEnd();
  }

  Widget _doneCard(String h, String v, Color c) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor, width: 2)),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            child: Center(child: Text(h, style: duoFont(size: 9.5, weight: FontWeight.w900, color: Colors.white, spacing: .4))),
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(v, style: duoFont(size: 16, weight: FontWeight.w900))),
        ]),
      ),
    );
  }

  void _claim() {
    widget.state.finishStory(s.id);
    widget.sfx.play('finish.mp3');
    ConfettiOverlay.show(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 16, 4),
            child: Row(children: [
              IconButton(onPressed: () { widget.tts.stop(); Navigator.pop(context); }, icon: const Icon(Icons.close_rounded), color: Duo.textLight),
              Expanded(child: DuoBar(pct: s.beats.isEmpty ? 0 : _idx / s.beats.length, color: Duo.amber)),
              const SizedBox(width: 10),
              const Icon(Icons.bolt_rounded, size: 20, color: Duo.blue),
              Text('∞', style: duoFont(size: 15, weight: FontWeight.w900, color: Duo.blue)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(s.title, style: duoFont(size: 17, weight: FontWeight.w900)),
            ),
          ),
          Expanded(
            child: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 6, 16, 20), children: List.of(_shown)),
          ),
          if (_bandMsg.isNotEmpty)
            Container(
              width: double.infinity,
              color: _bandOk ? Duo.greenLight : Duo.roseLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(_bandMsg, style: duoFont(size: 14, weight: FontWeight.w900, color: _bandOk ? Duo.greenDark : Duo.roseDark)),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 2))),
            child: SafeArea(
              top: false,
              child: DuoButton(
                label: _finished ? 'CLAIM XP' : 'CONTINUE',
                color: _finished ? Duo.blue : Duo.green,
                borderColor: _finished ? Duo.blueDark : Duo.greenDark,
                disabled: _busy,
                onTap: _finished ? _claim : (_busy ? null : _next),
                wide: true,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Wrapper to hold per-beat ephemeral state (picked options) without
/// polluting the parent state.
class _StatefulBeat extends StatefulWidget {
  final Widget Function(BuildContext, void Function(VoidCallback)) builder;
  const _StatefulBeat({super.key, required this.builder});
  @override
  State<_StatefulBeat> createState() => _StatefulBeatState();
}

class _StatefulBeatState extends State<_StatefulBeat> {
  void _set(VoidCallback f) => setState(f);
  @override
  Widget build(BuildContext context) => widget.builder(context, _set);
}
