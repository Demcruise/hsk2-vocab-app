import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../data/services.dart';
import 'duo.dart';
import 'speak_practice.dart';
import 'widgets.dart';
import 'writing.dart';

/// Full-screen flashcard "lesson" — ports the PWA session view:
/// X + progress bar + flippable card + sentences + Sulit/Baik/Mudah footer.
class SessionScreen extends StatefulWidget {
  final AppState state;
  final ContentRepository content;
  final TtsService tts;
  final SfxService sfx;
  final List<int> cardIdx;
  final int startAt;
  final String title;
  final String? lessonKey; // 'ui_li' — marks the path node done on completion

  const SessionScreen({
    super.key,
    required this.state,
    required this.content,
    required this.tts,
    required this.sfx,
    required this.cardIdx,
    required this.title,
    this.startAt = 0,
    this.lessonKey,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late int _idx;
  bool _flipped = false;
  bool _done = false;

  AppState get S => widget.state;
  ContentRepository get R => widget.content;
  List<int> get cards => widget.cardIdx;
  VocabWord get word => R.vocab[cards[_idx]];

  @override
  void initState() {
    super.initState();
    _idx = widget.startAt.clamp(0, cards.length - 1);
    S.wid = word.id;
    S.save();
  }

  void _show(int n) {
    if (cards.isEmpty) return;
    setState(() {
      _idx = n.clamp(0, cards.length - 1);
      _flipped = false;
      S.wid = word.id;
      S.save();
    });
  }

  void _rate(int rating) {
    S.rateCard(word.id, rating);
    if (rating >= 2) widget.sfx.play('correct.wav');
    if (_idx < cards.length - 1) {
      _show(_idx + 1);
    } else {
      // lesson finished — celebrate + mark the path node done
      final key = widget.lessonKey;
      if (key != null) S.finishLesson(key);
      widget.sfx.play('finish.mp3');
      ConfettiOverlay.show(context);
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _doneView();
    final v = word;
    final rad = R.radicalFor(v.hanzi);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          // top bar: X + progress + meta
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 16, 4),
            child: Row(children: [
              IconButton(
                onPressed: () { widget.tts.stop(); Navigator.of(context).pop(); },
                icon: const Icon(Icons.close_rounded),
                color: Duo.textLight,
              ),
              Expanded(child: DuoBar(pct: (_idx + 1) / cards.length)),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: duoFont(size: 11, weight: FontWeight.w800, color: Duo.textLight, spacing: .5),
                ),
              ),
            ]),
          ),
          // card + sentences
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                GestureDetector(
                  onTap: () => setState(() => _flipped = !_flipped),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                        left: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                        right: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                        bottom: BorderSide(color: Theme.of(context).dividerColor, width: 6),
                      ),
                    ),
                    child: Column(children: [
                      Row(children: [
                        Text('${_idx + 1}/${cards.length}  |  #${v.id}',
                            style: duoFont(size: 11, weight: FontWeight.w800, color: Duo.textLight, spacing: .5)),
                        const Spacer(),
                        // speed toggle
                        GestureDetector(
                          onTap: () => setState(() {
                            widget.tts.speed = widget.tts.speed == 'slow' ? 'normal' : 'slow';
                            S.speed = widget.tts.speed;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.tts.speed == 'slow' ? Duo.blueLight : Theme.of(context).dividerColor.withValues(alpha: .4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.tts.speed == 'slow' ? '🐢 Slow' : '🔊 Normal',
                              style: duoFont(size: 11, weight: FontWeight.w800,
                                  color: widget.tts.speed == 'slow' ? Duo.blueDark : Duo.textLight),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => widget.tts.speak(v.hanzi),
                          child: const Text('🔊', style: TextStyle(fontSize: 20)),
                        ),
                      ]),
                      const SizedBox(height: 18),
                      Text(v.hanzi, style: duoFont(size: 46, weight: FontWeight.w900, height: 1.1)),
                      const SizedBox(height: 4),
                      Text(v.pinyin, style: duoFont(size: 19, weight: FontWeight.w800, color: Duo.blue)),
                      const SizedBox(height: 10),
                      if (_flipped) ...[
                        Text(v.meaning, textAlign: TextAlign.center, style: duoFont(size: 17, weight: FontWeight.w800)),
                        if (v.traditional != v.hanzi) ...[
                          const SizedBox(height: 4),
                          Text('Traditional: ${v.traditional}', style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
                        ],
                        if (rad != null) ...[
                          const SizedBox(height: 6),
                          Text('Radical: ${rad.radical} (${rad.pinyin}) — ${rad.meaning}',
                              textAlign: TextAlign.center,
                              style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
                        ],
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Tap to see sentences',
                              style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
                        ),
                    ]),
                  ),
                ),
                // quick actions: mark known / speak / write
                Row(children: [
                  Expanded(child: _quickBtn(context, S.isKnown(v.id) ? '✓ Known' : '✅ Know it', S.isKnown(v.id), () {
                    if (S.isKnown(v.id)) {
                      duoToast(context, 'Already marked as known');
                    } else {
                      S.markKnown(v.id);
                      setState(() {});
                      duoToast(context, 'Marked as known ✓');
                    }
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: _quickBtn(context, '🎤 Speak', false, () {
                    SpeakSheet.show(context, word: v.hanzi, pinyin: v.pinyin, meaning: v.meaning,
                        sentence: v.sentences.isNotEmpty ? v.sentences.first.hanzi : '',
                        asr: asrService, tts: widget.tts);
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: _quickBtn(context, '✍️ Write', false, () {
                    WritingScreen.open(context, S, R, v.hanzi.split(''), title: 'Write ${v.hanzi}');
                  })),
                ]),
                if (_flipped) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Example Sentences (tap a character for details):',
                        style: duoFont(size: 12, weight: FontWeight.w900, color: Duo.textLight, spacing: .4)),
                  ),
                  ...v.sentences.asMap().entries.map((e) => _sentence(context, e.key + 1, e.value)),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          // footer: rating or nav
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 2))),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(children: [
              if (_flipped)
                Row(children: [
                  Expanded(child: DuoButton(label: 'Hard', emoji: '🔥', color: Duo.orange, borderColor: Duo.orangeDark, onTap: () => _rate(1))),
                  const SizedBox(width: 10),
                  Expanded(child: DuoButton(label: 'Good', emoji: '✅', color: Duo.blue, borderColor: Duo.blueDark, onTap: () => _rate(2))),
                  const SizedBox(width: 10),
                  Expanded(child: DuoButton(label: 'Easy', emoji: '⚡', onTap: () => _rate(3))),
                ])
              else
                DuoButton(label: 'Flip card', icon: Icons.flip_rounded, onTap: () => setState(() => _flipped = true), wide: true),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DuoButton.secondary(label: '◀', onTap: _idx > 0 ? () => _show(_idx - 1) : null, disabled: _idx <= 0)),
                const SizedBox(width: 10),
                Expanded(child: DuoButton.secondary(label: '▶', onTap: () => _show((_idx + 1) % cards.length))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _quickBtn(BuildContext context, String label, bool active, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Duo.greenLight.withValues(alpha: dark ? .18 : 1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(11),
          border: Border(
            top: BorderSide(color: active ? Duo.green : Theme.of(context).dividerColor, width: 2),
            left: BorderSide(color: active ? Duo.green : Theme.of(context).dividerColor, width: 2),
            right: BorderSide(color: active ? Duo.green : Theme.of(context).dividerColor, width: 2),
            bottom: BorderSide(color: active ? Duo.green : Theme.of(context).dividerColor, width: 3),
          ),
        ),
        child: Center(
          child: Text(label,
              style: duoFont(size: 12, weight: FontWeight.w900,
                  color: active ? (dark ? Duo.green : Duo.greenDark) : (dark ? Duo.dTextLight : Duo.textLight))),
        ),
      ),
    );
  }

  Widget _sentence(BuildContext context, int n, Sentence s) {
    return DuoCard(
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$n.', style: duoFont(size: 12, weight: FontWeight.w800, color: Duo.textLight)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: HanziText(s.hanzi, fontSize: 16)),
              GestureDetector(
                onTap: () => widget.tts.speak(s.hanzi),
                child: const Padding(padding: EdgeInsets.only(left: 6), child: Text('🔊', style: TextStyle(fontSize: 15))),
              ),
            ]),
            const SizedBox(height: 3),
            Text(s.pinyin, style: duoFont(size: 12.5, weight: FontWeight.w700, color: Duo.blue)),
            Text(s.en, style: duoFont(size: 12.5, weight: FontWeight.w600, color: Duo.textLight)),
          ]),
        ),
      ]),
    );
  }

  /// "Lesson complete!" celebration — mirrors the PWA sessDone overlay.
  Widget _doneView() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎉', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 14),
              Text('Lesson complete!', style: duoFont(size: 26, weight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('You finished ${widget.title} — this path point is now checked off.',
                  textAlign: TextAlign.center,
                  style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight)),
              const SizedBox(height: 26),
              DuoButton(
                label: 'CONTINUE',
                onTap: () { widget.tts.stop(); Navigator.of(context).pop(); },
                wide: true,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
