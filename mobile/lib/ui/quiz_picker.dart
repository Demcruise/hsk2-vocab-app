import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../data/services.dart';
import 'duo.dart';
import 'quiz_screen.dart';

/// Quiz tab landing — pick "Latihan Bebas" (all words) or a topic unit,
/// matching the learn path. Quiz launches as a fullscreen route.
class QuizPickerScreen extends StatelessWidget {
  final AppState state;
  final ContentRepository content;
  final TtsService tts;
  final SfxService sfx;
  const QuizPickerScreen({super.key, required this.state, required this.content, required this.tts, required this.sfx});

  static void startQuiz(BuildContext context, {required AppState state, required ContentRepository content, required TtsService tts, required SfxService sfx, String? topic, List<VocabWord>? pool, String? forceType, String? title}) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => QuizScreen(
        state: state, content: content, sfx: sfx, tts: tts,
        topic: topic, pool: pool, forceType: forceType, title: title,
        onQuit: () => Navigator.of(context).pop(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final total = content.vocab.length;
        final mastered = state.masteredCount;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
          Text('Pick a practice', style: duoFont(size: 22, weight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text('Mixed practice: translate, listen, speak & write',
              style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight)),
          const SizedBox(height: 14),
          _freeTile(context, mastered, total),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _skillTile(context, '🎧', 'Listening', 'listen')),
            const SizedBox(width: 8),
            Expanded(child: _skillTile(context, '🎤', 'Speaking', 'speak')),
            const SizedBox(width: 8),
            Expanded(child: _skillTile(context, '✍️', 'Writing', 'write')),
          ]),
          const SizedBox(height: 10),
          for (final u in content.units) ...[
            _unitTile(context, u, dark),
            const SizedBox(height: 10),
          ],
        ]);
      },
    );
  }

  Widget _freeTile(BuildContext context, int mastered, int total) {
    final pct = total == 0 ? 0.0 : mastered / total;
    return GestureDetector(
      onTap: () => startQuiz(context, state: state, content: content, tts: tts, sfx: sfx),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Duo.green, Duo.greenDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          border: const Border(bottom: BorderSide(color: Duo.greenDark, width: 4)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('⚡', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Free Practice', style: duoFont(size: 15, weight: FontWeight.w900, color: Colors.white)),
            Text('All $total words • ${content.levelLabel}', style: duoFont(size: 12, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .85))),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: Colors.white.withValues(alpha: .3), valueColor: const AlwaysStoppedAnimation(Colors.white))),
          ])),
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
        ]),
      ),
    );
  }

  Widget _skillTile(BuildContext context, String icon, String name, String type) {
    final misses = state.skillMiss(type);
    return GestureDetector(
      onTap: () => startQuiz(context, state: state, content: content, tts: tts, sfx: sfx,
          forceType: type, title: '$name Practice'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 2),
            left: BorderSide(color: Theme.of(context).dividerColor, width: 2),
            right: BorderSide(color: Theme.of(context).dividerColor, width: 2),
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 4),
          ),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(name, style: duoFont(size: 12.5, weight: FontWeight.w900)),
          Text('$misses missed', style: duoFont(size: 11, weight: FontWeight.w700, color: Duo.textLight)),
        ]),
      ),
    );
  }

  Widget _unitTile(BuildContext context, Unit u, bool dark) {
    var mst = 0;
    for (final l in u.lessons) {
      for (final i in l.vocabIdx) {
        if (state.wordLevel(content.vocab[i].id) >= 3) mst++;
      }
    }
    final pct = u.wordCount == 0 ? 0.0 : mst / u.wordCount;
    final c = Color(ContentRepository.unitColors[u.key] ?? 0xFF1CB0F6);
    return GestureDetector(
      onTap: () => startQuiz(context, state: state, content: content, tts: tts, sfx: sfx, topic: u.key, title: u.name),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 2),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: c.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(ContentRepository.unitIcons[u.key] ?? '📚', style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, style: duoFont(size: 14.5, weight: FontWeight.w900)),
            Text('${u.wordCount} words • ${(pct * 100).round()}% mastered', style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: Theme.of(context).dividerColor, valueColor: const AlwaysStoppedAnimation(Duo.green))),
          ])),
          const Icon(Icons.play_arrow_rounded, color: Duo.textLight, size: 26),
        ]),
      ),
    );
  }
}
