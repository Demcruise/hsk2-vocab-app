import 'package:flutter/material.dart';
import '../data/services.dart';
import 'duo.dart';

/// Speaking practice panel — ASR (zh-CN) via speech_to_text when available,
/// otherwise a self-check flow (hear model → speak → self-rate).
///
/// onDone(ok): called when the user is scored. Pass null to keep it open
/// (caller decides).
class SpeakPanel extends StatefulWidget {
  final String target; // hanzi to pronounce
  final AsrService asr;
  final TtsService tts;
  final void Function(bool ok, String heard)? onDone;
  final bool autoFinish; // auto-close after correct (sheet mode)
  const SpeakPanel({super.key, required this.target, required this.asr, required this.tts, this.onDone, this.autoFinish = false});

  @override
  State<SpeakPanel> createState() => _SpeakPanelState();
}

class _SpeakPanelState extends State<SpeakPanel> {
  bool _busy = false;
  bool _selfMode = false;
  String _status = 'Tap 🎤 and speak';
  String _heard = '';

  @override
  void dispose() {
    widget.asr.cancel();
    super.dispose();
  }

  Future<void> _listen() async {
    if (_busy) return;
    setState(() { _busy = true; _status = 'Listening… say it now'; _heard = ''; });
    final heard = await widget.asr.listenOnce('zh-CN');
    if (!mounted) return;
    if (heard == null) {
      // ASR unsupported/failed → self-check
      setState(() { _busy = false; _selfMode = true; _status = 'Mic/ASR not supported — hear the example, speak, rate yourself'; });
      widget.tts.speak(widget.target);
      return;
    }
    final ok = AsrService.matchHanzi(heard, widget.target);
    setState(() {
      _busy = false;
      _heard = 'You said: $heard';
      _status = ok ? 'Nice! Your pronunciation matches ✅' : 'Not matching — try again';
    });
    widget.onDone?.call(ok, heard);
  }

  void _selfScore(bool ok) {
    setState(() { _selfMode = false; _status = ok ? 'Nice! ✅' : 'Keep practicing 💪'; });
    widget.onDone?.call(ok, '');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: _listen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 84, height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _busy ? Duo.rose : Duo.blue,
            boxShadow: [BoxShadow(color: _busy ? Duo.roseDark : Duo.blueDark, offset: const Offset(0, 4))],
          ),
          child: Icon(_busy ? Icons.mic : Icons.mic_none_rounded, size: 38, color: Colors.white),
        ),
      ),
      const SizedBox(height: 14),
      Text(_status, textAlign: TextAlign.center,
          style: duoFont(size: 13.5, weight: FontWeight.w700, color: dark ? Duo.dTextLight : Duo.textLight)),
      if (_heard.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(_heard, textAlign: TextAlign.center, style: duoFont(size: 15, weight: FontWeight.w800)),
      ],
      if (_selfMode) ...[
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: DuoButton(label: '✅ Correct', small: true, onTap: () => _selfScore(true))),
          const SizedBox(width: 10),
          Expanded(child: DuoButton(label: '❌ Not yet', small: true, color: Duo.orange, borderColor: Duo.orangeDark, onTap: () => _selfScore(false))),
        ]),
      ],
    ]);
  }
}

/// Bottom-sheet wrapper used from flashcard sessions.
class SpeakSheet extends StatelessWidget {
  final String word; // hanzi
  final String pinyin;
  final String meaning;
  final String sentence;
  final AsrService asr;
  final TtsService tts;
  const SpeakSheet({super.key, required this.word, required this.pinyin, required this.meaning, required this.sentence, required this.asr, required this.tts});

  static void show(BuildContext context, {required String word, required String pinyin, required String meaning, String sentence = '', required AsrService asr, required TtsService tts}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SpeakSheet(word: word, pinyin: pinyin, meaning: meaning, sentence: sentence, asr: asr, tts: tts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Speaking Practice', style: duoFont(size: 16, weight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(word, style: duoFont(size: 44, weight: FontWeight.w900, height: 1.1)),
          Text(pinyin, style: duoFont(size: 16, weight: FontWeight.w800, color: Duo.blue)),
          Text(meaning, textAlign: TextAlign.center, style: duoFont(size: 13, weight: FontWeight.w600, color: Duo.textLight)),
          if (sentence.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(sentence, textAlign: TextAlign.center, style: duoFont(size: 15, weight: FontWeight.w700)),
          ],
          const SizedBox(height: 10),
          DuoButton.secondary(label: '🔊 Hear example', small: true, onTap: () => tts.speak(sentence.isNotEmpty ? sentence : word)),
          const SizedBox(height: 16),
          SpeakPanel(target: sentence.isNotEmpty ? sentence : word, asr: asr, tts: tts),
        ]),
      ),
    );
  }
}
