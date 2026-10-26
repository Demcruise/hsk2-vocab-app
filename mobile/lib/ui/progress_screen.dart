import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../data/services.dart';
import 'duo.dart';
import 'quiz_picker.dart';
import 'story_screen.dart';
import 'widgets.dart';

/// Progress tab: streak banner + stats grid + practice hub + achievements + backup/reset/version.
class ProgressScreen extends StatelessWidget {
  final AppState state;
  final ContentRepository content;
  final BackupService backup;
  final TtsService tts;
  final SfxService sfx;
  const ProgressScreen({super.key, required this.state, required this.content, required this.backup, required this.tts, required this.sfx});

  static const appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final total = content.vocab.length;
        final mastered = state.masteredCount;
        final learning = state.learningCount;
        final baru = total - mastered - learning;
        final ach = state.achievements(total);

        return ListView(padding: const EdgeInsets.all(16), children: [
          // streak banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF9600), Color(0xFFFF7A00)]),
              borderRadius: BorderRadius.circular(18),
              border: const Border(bottom: BorderSide(color: Duo.orangeDark, width: 4)),
            ),
            child: Column(children: [
              Text('${state.streak}', style: duoFont(size: 40, weight: FontWeight.w900, color: Colors.white, height: 1)),
              Text('🔥 Study Streak', style: duoFont(size: 14, weight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 14),
          // stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _stat('$total', 'Total'),
              _stat('$mastered', 'Memorized'),
              _stat('$learning', 'Learning'),
              _stat('${baru < 0 ? 0 : baru}', 'New'),
              _stat('${state.xp}', 'XP'),
              _stat('${state.quizzes}', 'Quiz'),
            ],
          ),
          const SizedBox(height: 16),
          // practice hub — weakness tiles per skill + mistakes recap
          _practiceHub(context),
          const SizedBox(height: 16),
          // stories per topic
          _storiesCard(context),
          const SizedBox(height: 16),
          // achievements
          DuoCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🏆 Achievements', style: duoFont(size: 15, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...ach.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Opacity(
                      opacity: a.unlocked ? 1 : .45,
                      child: Row(children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.name, style: duoFont(size: 14, weight: FontWeight.w800)),
                            Text(a.desc, style: duoFont(size: 11.5, weight: FontWeight.w600, color: Duo.textLight)),
                          ]),
                        ),
                        Text(a.unlocked ? '✓' : '🔒',
                            style: TextStyle(fontSize: 15, color: a.unlocked ? Duo.green : Duo.textLight, fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  )),
            ]),
          ),
          const SizedBox(height: 16),
          // backup / restore
          DuoCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💾 Save & Load Progress', style: duoFont(size: 15, weight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                '${state.recordedCount} words logged • ${state.masteredCount} memorized • ${state.xp} XP'
                '${state.savedAt.isNotEmpty ? ' • saved ${state.savedAt}' : ''}',
                style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DuoButton(
                    label: 'Save',
                    icon: Icons.download_rounded,
                    color: Duo.blue,
                    borderColor: Duo.blueDark,
                    onTap: () async {
                      final ok = await backup.exportJson(state.payload(), level: state.level);
                      if (context.mounted) duoToast(context, ok ? 'Progress saved!' : 'Failed to save');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DuoButton.secondary(
                    label: 'Load file',
                    icon: Icons.upload_rounded,
                    onTap: () async {
                      final p = await backup.importJson();
                      if (context.mounted) {
                        duoToast(context, p != null && state.importPayload(p) ? 'Progress loaded!' : 'Invalid file');
                      }
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              DuoButton.secondary(
                label: 'Copy backup JSON',
                icon: Icons.copy_rounded,
                wide: true,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _prettyPayload()));
                  duoToast(context, 'Backup copied!');
                },
              ),
            ]),
          ),
          const SizedBox(height: 16),
          // version + reset
          DuoCard(
            child: Column(children: [
              Text('App version: $appVersion', style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
              const SizedBox(height: 10),
              DuoButton(
                label: 'Reset all progress',
                icon: Icons.delete_forever_rounded,
                color: Duo.rose,
                borderColor: Duo.roseDark,
                wide: true,
                onTap: () => _confirmReset(context),
              ),
            ]),
          ),
          const SizedBox(height: 30),
          Center(child: SvgPicture.asset('assets/svg/mascot.svg', width: 70, height: 70)),
          const SizedBox(height: 20),
        ]);
      },
    );
  }

  /// Practice Hub — tiles per skill showing miss counters; tapping launches
  /// a targeted quiz restricted to words the user got wrong.
  Widget _practiceHub(BuildContext context) {
    final mistakes = state.mistakeIds()
        .map((id) => content.vocab.where((v) => v.id == id).firstOrNull)
        .whereType<VocabWord>()
        .toList();
    final tiles = [
      ('🎧', 'Listening', 'listen', Duo.blue, Duo.blueDark),
      ('🎤', 'Speaking', 'speak', Duo.purple, const Color(0xFFA560E8)),
      ('✍️', 'Writing', 'write', Duo.orange, Duo.orangeDark),
      ('📖', 'Hard words', 'bank', Duo.rose, Duo.roseDark),
    ];
    return DuoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💪 Practice Hub', style: duoFont(size: 15, weight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Targeted practice from your mistakes — ${mistakes.length} words marked',
            style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
            for (final t in tiles)
              _hubTile(context, t.$1, t.$2, t.$3, t.$4, t.$5,
                  t.$3 == 'bank' ? mistakes.length : state.skillMiss(t.$3), mistakes),
          ],
        ),
      ]),
    );
  }

  Widget _hubTile(BuildContext context, String emoji, String name, String skill, Color c, Color cDark, int misses, List<VocabWord> pool) {
    final disabled = pool.isEmpty;
    return GestureDetector(
      onTap: disabled
          ? () => duoToast(context, 'No mistakes yet — play a quiz first!')
          : () => QuizPickerScreen.startQuiz(context,
              state: state, content: content, tts: tts, sfx: sfx,
              pool: pool, forceType: skill == 'bank' ? null : skill, title: '$name Practice'),
      child: Opacity(
        opacity: disabled ? .55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(name, style: duoFont(size: 12.5, weight: FontWeight.w900)),
                Text(skill == 'bank' ? '$misses words' : '$misses missed',
                    style: duoFont(size: 11, weight: FontWeight.w800, color: misses > 0 ? c : Duo.textLight)),
              ]),
            ),
            Icon(Icons.play_arrow_rounded, size: 22, color: cDark),
          ]),
        ),
      ),
    );
  }

  /// Storybook — one interactive story per topic (HSK-appropriate vocabulary).
  Widget _storiesCard(BuildContext context) {
    final stories = content.stories;
    if (stories.isEmpty) return const SizedBox.shrink();
    return DuoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('📚 Stories', style: duoFont(size: 15, weight: FontWeight.w900)),
          const Spacer(),
          Text('${stories.where((s) => state.storyDone.contains(s.topic)).length}/${stories.length}',
              style: duoFont(size: 12, weight: FontWeight.w900, color: Duo.green)),
        ]),
        const SizedBox(height: 4),
        Text('Interactive stories per topic — read, listen, and answer.',
            style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
            for (final st in stories)
              _storyTile(context, st),
          ],
        ),
      ]),
    );
  }

  Widget _storyTile(BuildContext context, Story st) {
    final done = state.storyDone.contains(st.topic);
    final icon = ContentRepository.unitIcons[st.topic] ?? '📖';
    return GestureDetector(
      onTap: () => StoryScreen.open(context, state: state, content: content, topicOrId: st.topic, tts: tts, sfx: sfx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: done ? Duo.amber : Theme.of(context).dividerColor, width: 2),
            left: BorderSide(color: done ? Duo.amber : Theme.of(context).dividerColor, width: 2),
            right: BorderSide(color: done ? Duo.amber : Theme.of(context).dividerColor, width: 2),
            bottom: BorderSide(color: done ? Duo.amber : Theme.of(context).dividerColor, width: 4),
          ),
        ),
        child: Row(children: [
          Text(done ? '📗' : icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(st.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: duoFont(size: 11.5, weight: FontWeight.w900)),
              Text(done ? 'Done ✓' : '${st.beats.length} scenes',
                  style: duoFont(size: 10.5, weight: FontWeight.w800, color: done ? Duo.amber : Duo.textLight)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _prettyPayload() {
    final j = state.payload();
    return const JsonEncoder.withIndent('  ').convert(j);
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Reset progress?', style: duoFont(size: 17, weight: FontWeight.w900)),
        content: Text('All word levels, XP, streak, and known marks will be deleted.', style: duoFont(size: 13, weight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: duoFont(weight: FontWeight.w800, color: Duo.textLight)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); state.resetProgress(); },
            child: Text('Reset', style: duoFont(weight: FontWeight.w900, color: Duo.rose)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String n, String label) => DuoCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(n, style: duoFont(size: 26, weight: FontWeight.w900, color: Duo.green)),
          Text(label, style: duoFont(size: 12, weight: FontWeight.w800, color: Duo.textLight)),
        ]),
      );
}
