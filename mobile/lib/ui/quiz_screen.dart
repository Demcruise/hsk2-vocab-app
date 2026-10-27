import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../data/services.dart';
import 'duo.dart';
import 'fi_sticker.dart';
import 'speak_practice.dart';
import 'widgets.dart';
import 'writing.dart';

/// Exercise types in a mixed quiz session.
enum QType { hz2py, py2hz, hz2mn, bank, listen, speak, write }

class _Q {
  final VocabWord word;
  final Sentence sent;
  final List<String> answer;
  final List<String> bank;
  final List<int> sel = [];
  final QType type;
  final String? ch; // target char for write
  final List<String> opts; // multiple-choice options (recognition types)
  final int ansIdx; // index of the correct option in [opts]
  int selMc = -1; // picked option index
  bool firstTry = true;
  _Q(this.word, this.sent, this.answer, this.bank,
      {this.type = QType.bank, this.ch, this.opts = const [], this.ansIdx = -1});
}

/// Exercise screen — Duolingo-style mixed exercise set:
/// translate (word-bank), listen, speak, write.
class QuizScreen extends StatefulWidget {
  final AppState state;
  final ContentRepository content;
  final SfxService sfx;
  final TtsService tts;
  final VoidCallback? onQuit;
  final String? topic; // topic key → filter vocab
  final List<VocabWord>? pool; // explicit word pool (e.g. mistakes)
  final String? forceType; // 'listen'|'speak'|'write' → all questions of that type
  final String? title;
  const QuizScreen({super.key, required this.state, required this.content, required this.sfx, required this.tts, this.onQuit, this.topic, this.pool, this.forceType, this.title});

  @override
  State<QuizScreen> createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  static const _newPurple = Color(0xFFA568CC);

  List<_Q> _qs = [];
  int _idx = 0, _right = 0, _hearts = 5, _row = 0;
  final List<int> _wrongIds = [];
  bool _answered = false;
  bool _lastCorrect = false;
  String _ansText = '';
  bool _done = false;
  bool _showReview = false;
  bool _perfect = false;

  @visibleForTesting
  List<String> get debugBank => _qs.isEmpty ? const [] : _qs[_idx].bank;
  @visibleForTesting
  List<String> get debugAnswer => _qs.isEmpty ? const [] : _qs[_idx].answer;
  @visibleForTesting
  QType? get debugType => _qs.isEmpty ? null : _qs[_idx].type;
  @visibleForTesting
  List<String> get debugOpts => _qs.isEmpty ? const [] : _qs[_idx].opts;
  @visibleForTesting
  int get debugAnsIdx => _qs.isEmpty ? -1 : _qs[_idx].ansIdx;
  @visibleForTesting
  bool get debugAnswered => _answered;
  @visibleForTesting
  bool get debugDone => _done;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Progressive mix: recognition first (hanzi→pinyin, pinyin→hanzi,
  /// hanzi→meaning), then sentence bank, then listening/speaking/writing.
  static const _mix = [
    QType.hz2py, QType.py2hz, QType.hz2mn, QType.bank, QType.listen,
    QType.hz2py, QType.hz2mn, QType.bank, QType.speak, QType.write,
  ];

  static const _mcField = {
    QType.hz2py: 'pinyin',
    QType.py2hz: 'hanzi',
    QType.hz2mn: 'meaning',
  };

  _Q _buildMc(VocabWord v, QType t, math.Random rnd) {
    final field = _mcField[t]!;
    String val(VocabWord w) => switch (field) {
          'pinyin' => w.pinyin,
          'hanzi' => w.hanzi,
          _ => w.meaning,
        };
    final ans = val(v);
    final opts = <String>[ans];
    final seen = <String>{ans};
    var tries = 0;
    while (opts.length < 4 && tries < 80) {
      tries++;
      final w = widget.content.vocab[rnd.nextInt(widget.content.vocab.length)];
      final o = val(w);
      if (!seen.contains(o)) { opts.add(o); seen.add(o); }
    }
    opts.shuffle(rnd);
    final s = widget.content.pickExerciseSentence(v, rnd);
    return _Q(v, s, const [], const [],
        type: t, opts: opts, ansIdx: opts.indexOf(ans));
  }

  void _start() {
    var vocab = widget.pool ?? widget.content.vocab;
    if (widget.topic != null) {
      vocab = vocab.where((v) => v.topic == widget.topic).toList();
    }
    final rnd = math.Random();
    final sh = [...vocab]..shuffle(rnd);
    _qs = sh.take(math.min(10, vocab.length)).toList().asMap().entries.map((e) {
      final v = e.value;
      var t = switch (widget.forceType) {
        'listen' => QType.listen,
        'speak' => QType.speak,
        'write' => QType.write,
        _ => _mix[e.key % _mix.length],
      };
      if (_mcField.containsKey(t)) return _buildMc(v, t, rnd);
      String? ch;
      if (t == QType.write) {
        ch = widget.content.writeCharFor(v);
        if (ch == null) t = QType.bank;
      }
      final s = widget.content.pickExerciseSentence(v, rnd);
      final ans = ContentRepository.enTokens(s.en);
      return _Q(v, s, ans, widget.content.buildBank(ans, rnd), type: t, ch: ch);
    }).toList();
    if (_qs.isEmpty) { _qs = []; }
    setState(() {
      _idx = 0;
      _right = 0;
      _hearts = 5;
      _row = 0;
      _wrongIds.clear();
      _answered = false;
      _done = false;
      _showReview = false;
    });
    _speakCurrent();
  }

  void _speakCurrent() {
    if (_idx >= _qs.length) return;
    final q = _qs[_idx];
    widget.tts.speak(_mcField.containsKey(q.type) ? q.word.hanzi : q.sent.hanzi);
  }

  void _tapBank(int i) {
    if (_answered) return;
    setState(() => _qs[_idx].sel.add(i));
  }

  void _tapAns(int j) {
    if (_answered) return;
    setState(() => _qs[_idx].sel.removeAt(j));
  }

  void _check() {
    if (_answered || _done) return;
    final q = _qs[_idx];
    if (_mcField.containsKey(q.type)) {
      if (q.selMc < 0) return;
      _resolve(q.selMc == q.ansIdx, answerText: q.opts[q.ansIdx]);
      return;
    }
    if (q.type != QType.bank && q.type != QType.listen) return;
    if (q.sel.isEmpty) return;
    final mine = q.sel.map((i) => q.bank[i]).join(' ');
    final ok = ContentRepository.normAnswer(mine) == ContentRepository.normAnswer(q.answer.join(' '));
    _resolve(ok);
  }

  void _pickMc(int i) {
    if (_answered) return;
    setState(() => _qs[_idx].selMc = i);
  }

  /// Unified grading for all exercise types — band, XP, hearts, re-queue,
  /// per-skill mistake tracking.
  void _resolve(bool ok, {String? answerText}) {
    if (_answered || _done) return;
    final q = _qs[_idx];
    setState(() {
      _answered = true;
      _lastCorrect = ok;
      _ansText = answerText ?? q.answer.join(' ');
      if (ok) {
        _right++;
        _row++;
        widget.sfx.play('correct.wav');
        if (q.firstTry) {
          _perfect = true;
          ConfettiOverlay.show(context);
          Future.delayed(const Duration(milliseconds: 950), () {
            if (mounted) setState(() => _perfect = false);
          });
        }
      } else {
        _hearts = math.max(0, _hearts - 1);
        _row = 0;
        _wrongIds.add(q.word.id);
        widget.sfx.play('incorrect.wav');
        // re-queue at end like Duolingo
        _qs.add(_Q(q.word, q.sent, q.answer, q.bank,
            type: q.type, ch: q.ch, opts: q.opts, ansIdx: q.ansIdx)
          ..firstTry = false);
      }
    });
    widget.state.recordQuizAnswer(q.word, ok, skill: switch (q.type) {
      QType.listen => 'listen',
      QType.speak => 'speak',
      QType.write => 'write',
      _ => null,
    });
  }

  void _next() {
    if (_hearts <= 0 || _idx + 1 >= _qs.length) { _finish(); return; }
    setState(() { _idx++; _answered = false; });
    _speakCurrent();
  }

  void _finish() {
    final pct = _qs.isEmpty ? 0 : (_right / _qs.length * 100).round();
    widget.state.finishQuizXp(pct);
    if (pct >= 50) {
      widget.sfx.play('finish.mp3');
      ConfettiOverlay.show(context);
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        Expanded(child: _done ? _doneView() : _exerciseView()),
      ]),
      if (_perfect) const _PerfectOverlay(),
    ]);
  }

  // ---------- exercise view ----------
  Widget _exerciseView() {
    if (_qs.isEmpty) return const SizedBox.shrink();
    final q = _qs[_idx];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final streak = _row >= 3;

    return Column(children: [
      // header: X + progress (gold + "N IN A ROW") + ⚡∞
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Row(children: [
          GestureDetector(
            onTap: widget.onQuit,
            child: const Icon(Icons.close_rounded, size: 26, color: Duo.textLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: streak ? 20 : 16,
              child: Stack(alignment: Alignment.center, children: [
                DuoBar(pct: _idx / _qs.length, height: streak ? 20 : 16,
                    color: streak ? Duo.amber : Duo.green),
                if (streak)
                  Text('$_row IN A ROW',
                      style: duoFont(size: 10, weight: FontWeight.w900, color: Colors.white, spacing: .8)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.bolt_rounded, size: 22, color: Duo.blue),
          Text('∞', style: duoFont(size: 16, weight: FontWeight.w900, color: Duo.blue)),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 12), children: [
          // pinyin toggle (kiri atas)
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => widget.state.toggleExPinyin(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.state.exPinyin ? Duo.blueLight : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    top: BorderSide(color: widget.state.exPinyin ? Duo.blue : Theme.of(context).dividerColor, width: 2),
                    left: BorderSide(color: widget.state.exPinyin ? Duo.blue : Theme.of(context).dividerColor, width: 2),
                    right: BorderSide(color: widget.state.exPinyin ? Duo.blue : Theme.of(context).dividerColor, width: 2),
                    bottom: BorderSide(color: widget.state.exPinyin ? Duo.blue : Theme.of(context).dividerColor, width: 4),
                  ),
                ),
                child: Text('拼音',
                    style: duoFont(size: 11, weight: FontWeight.w900,
                        color: widget.state.exPinyin ? Duo.blueDark : Duo.textLight, spacing: .5)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // badge
          _badge(q),
          Text(switch (q.type) {
            QType.hz2py => 'Choose the correct pinyin',
            QType.py2hz => 'Choose the correct hanzi',
            QType.hz2mn => 'What does this word mean?',
            QType.bank => 'Translate this sentence',
            QType.listen => 'Listen & write what you hear',
            QType.speak => 'Say this sentence',
            QType.write => 'Write this character',
          }, style: duoFont(size: 21, weight: FontWeight.w900, color: dark ? Duo.dText : Duo.text)),
          const SizedBox(height: 14),
          switch (q.type) {
            QType.bank || QType.listen => _bankBody(q, dark, listenMode: q.type == QType.listen),
            QType.speak => _speakBody(q, dark),
            QType.write => _writeBody(q, dark),
            _ => _mcBody(q, dark),
          },
        ]),
      ),
      // footer: CHECK or feedback band
      if (_answered)
        _band(q)
      else if (q.type == QType.bank || q.type == QType.listen)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: SafeArea(
            top: false,
            child: DuoButton(
              label: 'CHECK',
              onTap: q.sel.isEmpty ? null : _check,
              disabled: q.sel.isEmpty,
              wide: true,
            ),
          ),
        )
      else if (_mcField.containsKey(q.type))
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: SafeArea(
            top: false,
            child: DuoButton(
              label: 'CHECK',
              onTap: q.selMc < 0 ? null : _check,
              disabled: q.selMc < 0,
              wide: true,
            ),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: SafeArea(
            top: false,
            child: Center(
              child: GestureDetector(
                onTap: () => _resolve(false, answerText: q.type == QType.write ? (q.ch ?? '') : q.sent.hanzi),
                child: Text('SKIP',
                    style: duoFont(size: 13, weight: FontWeight.w900, color: Duo.textLight, spacing: .8)),
              ),
            ),
          ),
        ),
    ]);
  }

  // ---------- per-type bodies ----------
  Widget _bankBody(_Q q, bool dark, {bool listenMode = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (listenMode)
        Center(
          child: GestureDetector(
            onTap: () => widget.tts.speak(q.sent.hanzi),
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: Duo.blueLight.withValues(alpha: dark ? .18 : 1),
                shape: BoxShape.circle,
                border: Border.all(color: Duo.blue, width: 3),
              ),
              child: const Icon(Icons.volume_up_rounded, size: 52, color: Duo.blue),
            ),
          ),
        )
      else
        _bubbleRow(q, dark),
      const SizedBox(height: 16),
      // answer zone
      Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 2)),
        ),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (var j = 0; j < q.sel.length; j++)
            _chip(q.bank[q.sel[j]], key: Key('chip-ans-$j'), inAnswer: true, onTap: () => _tapAns(j), dark: dark),
        ]),
      ),
      const SizedBox(height: 14),
      // word bank
      Wrap(spacing: 9, runSpacing: 9, children: [
        for (var i = 0; i < q.bank.length; i++)
          _chip(q.bank[i], key: Key('chip-bank-$i'),
              used: q.sel.contains(i), onTap: () => _tapBank(i), dark: dark),
      ]),
      if (listenMode) ...[
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () => widget.tts.speakSlow(q.sent.hanzi),
            child: Text('🐢 play slowly', style: duoFont(size: 13, weight: FontWeight.w800, color: Duo.blue)),
          ),
        ),
      ],
    ]);
  }

  /// Recognition body: big hanzi/pinyin prompt + 4 tappable options (select → CHECK).
  Widget _mcBody(_Q q, bool dark) {
    final isPy = q.type == QType.py2hz;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: Column(children: [
          GestureDetector(
            onTap: () => widget.tts.speak(q.word.hanzi),
            child: const Icon(Icons.volume_up_rounded, size: 26, color: Duo.blue),
          ),
          const SizedBox(height: 6),
          Text(isPy ? q.word.pinyin : q.word.hanzi,
              style: duoFont(size: isPy ? 30 : 44, weight: FontWeight.w900, color: dark ? Duo.dText : Duo.text)),
          if (q.type == QType.hz2mn && widget.state.exPinyin)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(q.word.pinyin, style: duoFont(size: 14, weight: FontWeight.w700, color: Duo.blue)),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      for (var i = 0; i < q.opts.length; i++) ...[
        _mcOpt(q, i, dark),
        if (i < q.opts.length - 1) const SizedBox(height: 10),
      ],
    ]);
  }

  Widget _mcOpt(_Q q, int i, bool dark) {
    final sel = q.selMc == i;
    var border = Theme.of(context).dividerColor;
    var bg = Theme.of(context).cardColor;
    var fg = dark ? Duo.dText : Duo.text;
    if (_answered) {
      if (i == q.ansIdx) { border = Duo.greenDark; bg = Duo.greenLight.withValues(alpha: dark ? .15 : 1); fg = dark ? Duo.green : Duo.greenDark; }
      else if (sel) { border = Duo.roseDark; bg = Duo.roseLight.withValues(alpha: dark ? .15 : 1); fg = dark ? Duo.rose : Duo.roseDark; }
      else { fg = Duo.textLight; }
    } else if (sel) {
      border = Duo.blue; bg = Duo.blueLight.withValues(alpha: dark ? .18 : 1); fg = dark ? Duo.blue : Duo.blueDark;
    }
    return GestureDetector(
      onTap: _answered ? null : () => _pickMc(i),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: border, width: 2),
            left: BorderSide(color: border, width: 2),
            right: BorderSide(color: border, width: 2),
            bottom: BorderSide(color: border, width: 4),
          ),
        ),
        child: Center(child: Text(q.opts[i], style: duoFont(size: 17, weight: FontWeight.w800, color: fg))),
      ),
    );
  }

  Widget _speakBody(_Q q, bool dark) {
    if (_answered) return _bubbleRow(q, dark);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _bubbleRow(q, dark),
      const SizedBox(height: 14),
      SpeakPanel(
        target: q.sent.hanzi,
        tts: widget.tts,
        asr: asrService,
        onDone: (ok, heard) => _resolve(ok, answerText: q.sent.hanzi),
      ),
    ]);
  }

  Widget _writeBody(_Q q, bool dark) {
    final v = q.word;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(q.ch ?? v.hanzi, style: duoFont(size: 40, weight: FontWeight.w900)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.pinyin, style: duoFont(size: 15, weight: FontWeight.w800, color: Duo.blue)),
            Text(v.meaning, style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight)),
          ]),
        ),
      ]),
      const SizedBox(height: 10),
      Center(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor, width: 2),
          ),
          child: StrokeTraceView(
            ch: widget.content.strokesFor(q.ch ?? '')!,
            size: math.min(MediaQuery.sizeOf(context).width * .62, 250.0),
            onComplete: _answered ? (_) {} : (m) => _resolve(m == 0, answerText: q.ch ?? ''),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text('Follow the stroke guide — write the brightest stroke',
            style: duoFont(size: 12, weight: FontWeight.w600, color: Duo.textLight)),
      ),
    ]);
  }

  /// Mascot + speech bubble (shared by bank & speak).
  Widget _bubbleRow(_Q q, bool dark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SvgPicture.asset('assets/svg/mascot.svg', width: 86, height: 86),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.fromLTRB(34, 12, 14, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor, width: 2),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            // tail
            Positioned(
              left: -22, top: 12,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      left: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                      bottom: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -26, top: 0,
              child: GestureDetector(
                onTap: () => widget.tts.speak(q.sent.hanzi),
                child: const Icon(Icons.volume_up_rounded, size: 20, color: Duo.blue),
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _bubbleText(q, dark),
              if (widget.state.exPinyin)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(q.sent.pinyin,
                      style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.blue)),
                ),
            ]),
          ]),
        ),
      ),
    ]);
  }

  Widget _badge(_Q q) {
    final p = widget.state.prog[q.word.id];
    final isNew = p == null || (p.l == 0 && p.c == 0);
    final isHard = p != null && p.w > 0;
    if (!isNew && !isHard) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(isNew ? '✦' : '⚑',
            style: TextStyle(fontSize: 13, color: isNew ? _newPurple : Duo.rose)),
        const SizedBox(width: 6),
        Text(isNew ? 'NEW WORD' : 'HARD EXERCISE',
            style: duoFont(size: 11.5, weight: FontWeight.w900,
                color: isNew ? _newPurple : Duo.rose, spacing: .8)),
      ]),
    );
  }

  Widget _bubbleText(_Q q, bool dark) {
    final segs = widget.content.segmentHanzi(q.sent.hanzi);
    return Text.rich(TextSpan(children: [
      for (final s in segs)
        if (s.word == null)
          TextSpan(text: s.text)
        else
          TextSpan(
            text: s.text,
            style: TextStyle(
              color: _isNewWord(s.word!) ? _newPurple : (dark ? Duo.dText : Duo.text),
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: _isNewWord(s.word!) ? _newPurple : Duo.textLight,
            ),
          ),
    ], style: duoFont(size: 19, weight: FontWeight.w800, color: dark ? Duo.dText : Duo.text, height: 1.5)));
  }

  bool _isNewWord(VocabWord w) {
    final p = widget.state.prog[w.id];
    return p == null || (p.l == 0 && p.c == 0 && p.w == 0);
  }

  Widget _chip(String t, {Key? key, bool used = false, bool inAnswer = false, VoidCallback? onTap, required bool dark}) {
    final border = inAnswer ? Duo.greenDark : Theme.of(context).dividerColor;
    final bg = inAnswer ? Duo.greenLight.withValues(alpha: dark ? .15 : 1) : Theme.of(context).cardColor;
    final fg = inAnswer ? (dark ? Duo.green : Duo.greenDark) : (dark ? Duo.dText : Duo.text);
    return Opacity(
      opacity: used ? .28 : 1,
      child: GestureDetector(
        key: key,
        onTap: used ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              top: BorderSide(color: border, width: 2),
              left: BorderSide(color: border, width: 2),
              right: BorderSide(color: border, width: 2),
              bottom: BorderSide(color: border, width: 4),
            ),
          ),
          child: Text(t, style: duoFont(size: 15, weight: FontWeight.w800, color: fg)),
        ),
      ),
    );
  }

  Widget _band(_Q q) {
    return Container(
      width: double.infinity,
      color: _lastCorrect ? Duo.greenLight : Duo.roseLight,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: SafeArea(
        top: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_lastCorrect ? Icons.check_circle : Icons.cancel,
                color: _lastCorrect ? Duo.greenDark : Duo.roseDark, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: _lastCorrect
                  ? Text('${_pickPraise()} +10 XP',
                      style: duoFont(size: 16, weight: FontWeight.w900, color: Duo.greenDark))
                  : Text.rich(TextSpan(children: [
                      TextSpan(text: 'Correct answer: ', style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.roseDark)),
                      TextSpan(text: _ansText.isNotEmpty ? _ansText : q.answer.join(' '),
                          style: duoFont(size: 14, weight: FontWeight.w900, color: Duo.roseDark)),
                    ])),
            ),
          ]),
          const SizedBox(height: 12),
          DuoButton(
            label: 'CONTINUE',
            color: _lastCorrect ? Duo.green : Duo.rose,
            borderColor: _lastCorrect ? Duo.greenDark : Duo.roseDark,
            onTap: _next,
            wide: true,
          ),
        ]),
      ),
    );
  }

  String _pickPraise() => const ['Nice!', 'Awesome!', 'Great job!', 'Perfect!'][math.Random().nextInt(4)];

  // ---------- done view ----------
  Widget _doneView() {
    final pct = _qs.isEmpty ? 0 : (_right / _qs.length * 100).round();
    final win = pct >= 50;
    final bonus = pct >= 80 ? 20 : (pct >= 60 ? 10 : 5);
    return ListView(padding: const EdgeInsets.all(16), children: [
      DuoCard(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        child: Column(children: [
          win ? const FiSticker.medal() : SvgPicture.asset('assets/svg/mascot_sad.svg', width: 120, height: 120),
          const SizedBox(height: 14),
          Text(win ? 'Practice complete!' : 'Don\u2019t give up!', style: duoFont(size: 22, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            pct >= 90 ? 'Outstanding! Almost perfect.' : pct >= 70 ? 'Great! Keep it up.' : pct >= 50 ? 'Not bad — keep practicing.' : 'Practice more — you can do it.',
            style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight),
          ),
          const SizedBox(height: 18),
          Row(children: [
            _resultCard('TOTAL XP', '+$bonus', Duo.amber),
            const SizedBox(width: 10),
            _resultCard('ACCURACY', '$_right/${_qs.length}', Duo.blue),
            const SizedBox(width: 10),
            _resultCard('LIVES', '$_hearts', Duo.rose),
          ]),
          const SizedBox(height: 18),
          DuoButton(label: 'Retry quiz', icon: Icons.refresh_rounded, onTap: _start, wide: true),
          if (_wrongIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            DuoButton.secondary(label: 'Review mistakes', icon: Icons.list_alt_rounded, onTap: () => setState(() => _showReview = !_showReview), wide: true),
          ],
        ]),
      ),
      if (_showReview)
        DuoCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Review', style: duoFont(size: 14, weight: FontWeight.w900)),
            const SizedBox(height: 8),
            ..._wrongIds.map((id) {
              final v = widget.content.vocab.firstWhere((x) => x.id == id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Text(v.hanzi, style: duoFont(size: 18, weight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${v.pinyin} — ${v.meaning}', style: duoFont(size: 12.5, weight: FontWeight.w600, color: Duo.textLight))),
                ]),
              );
            }),
          ]),
        ),
    ]);
  }

  Widget _resultCard(String label, String val, Color c) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor, width: 2),
        ),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            child: Center(child: Text(label, style: duoFont(size: 10, weight: FontWeight.w900, color: Colors.white, spacing: .5))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(val, style: duoFont(size: 17, weight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }
}

/// "PERFECT" burst overlay — big tilted text + radial glow.
class _PerfectOverlay extends StatelessWidget {
  const _PerfectOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .2, end: 1),
          duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 340, height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFFC800).withValues(alpha: .45),
                  const Color(0xFFFFC800).withValues(alpha: .18),
                  Colors.transparent,
                ], stops: const [0, .45, .7]),
              ),
            ),
            Transform.rotate(
              angle: -.1,
              child: Text('PERFECT', style: TextStyle(
                fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 2,
                fontFamily: 'Nunito',
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 10
                  ..strokeJoin = StrokeJoin.round
                  ..color = const Color(0xFFB35300),
              )),
            ),
            Transform.rotate(
              angle: -.1,
              child: const Text('PERFECT', style: TextStyle(
                fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 2,
                fontFamily: 'Nunito', color: Color(0xFFFFA500),
                shadows: [Shadow(color: Color(0xFFB35300), offset: Offset(0, 4), blurRadius: 0)],
              )),
            ),
          ]),
        ),
      ),
    );
  }
}
