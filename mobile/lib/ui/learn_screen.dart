import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../data/services.dart';
import 'duo.dart';
import 'quiz_picker.dart';
import 'session_screen.dart';
import 'story_screen.dart';
import 'widgets.dart';
import 'writing.dart';

/// Learn tab: mode chips + wavy topic path of lesson nodes (Duolingo style).
class LearnScreen extends StatelessWidget {
  final AppState state;
  final ContentRepository content;
  final TtsService tts;
  final SfxService sfx;
  final Future<void> Function(String level)? onSwitchLevel;

  const LearnScreen({super.key, required this.state, required this.content, required this.tts, required this.sfx, this.onSwitchLevel});

  static const modeLabels = {
    'unmem': 'Not Memorized',
    'all': 'All',
    'new': 'New',
    'learning': 'Learning',
    'review': 'Review',
    'mastered': 'Mastered',
  };
  static const modeOrder = ['unmem', 'all', 'new', 'learning', 'review', 'mastered'];

  /// Open flashcard session jumped to a specific vocab index.
  static void openWord(BuildContext context, ContentRepository content, AppState state, TtsService tts, SfxService sfx, int vocabIdx) {
    state.mode = 'all';
    final list = state.cardList(content.vocab);
    final j = list.indexOf(vocabIdx);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionScreen(
        state: state,
        content: content,
        tts: tts,
        sfx: sfx,
        cardIdx: list,
        startAt: j >= 0 ? j : 0,
        title: 'Card #${content.vocab[vocabIdx].id}',
      ),
      fullscreenDialog: true,
    ));
  }

  void _openLesson(BuildContext context, Lesson l) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionScreen(
        state: state,
        content: content,
        tts: tts,
        sfx: sfx,
        cardIdx: l.vocabIdx,
        title: '${l.unitName} • ${l.lessonIndex + 1}/${l.lessonCount}',
        lessonKey: '${l.unitIndex}_${l.lessonIndex}',
      ),
      fullscreenDialog: true,
    ));
  }

  void _openPractice(BuildContext context) {
    final list = state.cardList(content.vocab);
    if (list.isEmpty) {
      duoToast(context, 'No cards');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionScreen(
        state: state,
        content: content,
        tts: tts,
        sfx: sfx,
        cardIdx: list,
        title: 'Practice • ${modeLabels[state.mode] ?? state.mode}',
      ),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            // level switcher — HSK 1 & HSK 2 kept fully separate
            Row(children: [
              for (final lv in const ['hsk1', 'hsk2']) ...[
                Expanded(child: _levelChip(context, lv)),
                if (lv == 'hsk1') const SizedBox(width: 8),
              ],
            ]),
            const SizedBox(height: 10),
            // mode chips (3-col grid like PWA)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.1,
              children: modeOrder.map((m) => _chip(context, modeLabels[m]!, m == state.mode, () {
                    state.mode = m;
                    state.save();
                    _openPractice(context);
                  })).toList(),
            ),
            const SizedBox(height: 10),
            DuoButton.secondary(
              label: 'Free practice • ${modeLabels[state.mode] ?? ''}',
              icon: Icons.shuffle_rounded,
              onTap: () => _openPractice(context),
              wide: true,
            ),
            const SizedBox(height: 18),
            ..._buildPath(context),
          ],
        );
      },
    );
  }

  Widget _bannerBtn(BuildContext context, String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: .5), width: 1.5),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
      ),
    );
  }

  Widget _levelChip(BuildContext context, String lv) {
    final active = content.level == lv;
    final emoji = lv == 'hsk1' ? '🐣' : '🚀';
    return GestureDetector(
      onTap: active ? null : () => onSwitchLevel?.call(lv),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Duo.green : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
            left: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
            right: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
            bottom: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 4),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text('${ContentRepository.levels[lv]}  ', style: duoFont(size: 13, weight: FontWeight.w900, color: active ? Colors.white : Duo.textLight)),
          Text('${content.levelSize(lv)} words', style: duoFont(size: 10, weight: FontWeight.w800, color: active ? Colors.white.withValues(alpha: .8) : Duo.textLight)),
        ]),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool active, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Duo.green : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
            left: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
            right: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
            bottom: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 4),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: duoFont(
            size: 10.5,
            weight: FontWeight.w900,
            color: active ? Colors.white : (dark ? Duo.dTextLight : Duo.textLight),
            spacing: .3,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPath(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final widgets = <Widget>[];
    var g = 0;
    var foundCurrent = false;

    for (var ui = 0; ui < content.units.length; ui++) {
      final u = content.units[ui];
      // unit banner
      widgets.add(Container(
        margin: const EdgeInsets.only(top: 14, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Duo.green,
          borderRadius: BorderRadius.circular(14),
          border: const Border(bottom: BorderSide(color: Duo.greenDark, width: 4)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SECTION ${ui + 1} • ${u.wordCount} WORDS',
                  style: duoFont(size: 10.5, weight: FontWeight.w800, color: Colors.white.withValues(alpha: .85), spacing: .6)),
              const SizedBox(height: 2),
              Text(u.name, style: duoFont(size: 18, weight: FontWeight.w900, color: Colors.white, height: 1.2)),
            ]),
          ),
          const SizedBox(width: 8),
          // quiz topik ini
          _bannerBtn(context, '⚡', () => QuizPickerScreen.startQuiz(context,
              state: state, content: content, tts: tts, sfx: sfx, topic: u.key, title: u.name)),
          const SizedBox(width: 8),
          // cerita topik ini
          _bannerBtn(context, state.storyDone.contains(u.key) ? '📗' : '📕',
              () => StoryScreen.open(context, state: state, content: content, topicOrId: u.key, tts: tts, sfx: sfx)),
          const SizedBox(width: 8),
          SvgPicture.asset('assets/svg/cn.svg', width: 44, height: 32),
        ]),
      ));

      // nodes on wavy path
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 42, bottom: 6),
        child: Column(
          children: [
            for (var li = 0; li < u.lessons.length; li++) ...[
              Builder(builder: (ctx) {
                final l = u.lessons[li];
                final st = _lessonState(l);
                final off = ContentRepository.waveOffsets[g % ContentRepository.waveOffsets.length];
                g++;
                final isCurrent = !st.done && !foundCurrent;
                if (isCurrent) foundCurrent = true;
                return _node(ctx, l, st, off, isCurrent, dark);
              }),
            ],
            // 📕 story node at the end of every unit's path
            _bookNode(context, u, dark),
          ],
        ),
      ));

      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text('✦   Unit done? On to the next one   ✦',
              style: duoFont(size: 11.5, weight: FontWeight.w800, color: dark ? Duo.dTextLight : Duo.textLight)),
        ),
      ));
    }
    return widgets;
  }

  ({int att, int mst, bool done, bool gold, double pct}) _lessonState(Lesson l) {
    var att = 0, mst = 0;
    for (final i in l.vocabIdx) {
      final lv = state.wordLevel(content.vocab[i].id);
      if (lv >= 1) att++;
      if (lv >= 3) mst++;
    }
    return (
      att: att,
      mst: mst,
      done: att == l.vocabIdx.length || state.isLessonDone('${l.unitIndex}_${l.lessonIndex}'),
      gold: mst == l.vocabIdx.length,
      pct: l.vocabIdx.isEmpty ? 0 : att / l.vocabIdx.length,
    );
  }

  /// Book node — opens the topic story (turns 📗 once finished).
  Widget _bookNode(BuildContext context, Unit u, bool dark) {
    final doneStory = state.storyDone.contains(u.key);
    final off = ContentRepository.waveOffsets[(u.lessons.length + 2) % ContentRepository.waveOffsets.length];
    return Transform.translate(
      offset: Offset(off, 0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(children: [
          _PressableNode(
            color: doneStory ? Duo.amber : (dark ? Duo.dCard : const Color(0xFFCE82FF)),
            shadow: doneStory ? Duo.amberDark : (dark ? const Color(0xFF222B30) : const Color(0xFFA560E8)),
            onTap: () => StoryScreen.open(context, state: state, content: content, topicOrId: u.key, tts: tts, sfx: sfx),
            child: const Text('📕', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 4),
          Text('Story', style: duoFont(size: 11, weight: FontWeight.w900, color: dark ? Duo.dTextLight : Duo.textLight)),
        ]),
      ),
    );
  }

  /// Long-press sheet on a lesson node — quick actions without entering the session.
  void _nodeSheet(BuildContext context, Lesson l) {
    final words = l.vocabIdx.map((i) => content.vocab[i]).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${l.unitName} • Lesson ${l.lessonIndex + 1}',
                style: duoFont(size: 15, weight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${words.length} words', style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
            const SizedBox(height: 14),
            DuoButton(
              label: '✅ I know all of these',
              onTap: () {
                for (final v in words) { state.markKnown(v.id); }
                Navigator.pop(ctx);
                duoToast(context, '${words.length} words marked as known');
              },
              wide: true,
            ),
            const SizedBox(height: 8),
            DuoButton.secondary(
              label: '⚡ Quiz this lesson',
              onTap: () {
                Navigator.pop(ctx);
                QuizPickerScreen.startQuiz(context,
                    state: state, content: content, tts: tts, sfx: sfx,
                    pool: words, title: '${l.unitName} • ${l.lessonIndex + 1}');
              },
              wide: true,
            ),
            const SizedBox(height: 8),
            DuoButton.secondary(
              label: '✍️ Writing practice',
              onTap: () {
                Navigator.pop(ctx);
                WritingScreen.open(context, state, content, words.map((v) => v.hanzi).join('').split(''));
              },
              wide: true,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _node(BuildContext context, Lesson l, ({int att, int mst, bool done, bool gold, double pct}) st, double off, bool isCurrent, bool dark) {
    final nodeColor = st.done ? (st.gold ? Duo.amber : Duo.green) : (isCurrent ? Duo.green : (dark ? Duo.dBorder : Duo.nodeOff));
    final shadow = st.done ? (st.gold ? Duo.amberDark : Duo.greenDark) : (isCurrent ? Duo.greenDark : (dark ? const Color(0xFF222B30) : Duo.nodeOffShadow));

    return Transform.translate(
      offset: Offset(off, 0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              if (isCurrent) ...[
                const Positioned(top: -34, child: _StartBubble()),
                CustomPaint(size: const Size(86, 86), painter: _RingPainter(st.pct, dark)),
              ],
              _PressableNode(
                color: nodeColor,
                shadow: shadow,
                onTap: () => _openLesson(context, l),
                onLongPress: () => _nodeSheet(context, l),
                child: Icon(
                  st.done ? Icons.check_rounded : Icons.star_rounded,
                  size: 34,
                  color: st.done || isCurrent ? Colors.white : (dark ? Duo.dTextLight : const Color(0xFFAFAFAF)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Text('${l.lessonIndex + 1}', style: duoFont(size: 12, weight: FontWeight.w900, color: dark ? Duo.dTextLight : Duo.textLight)),
        ]),
      ),
    );
  }
}

class _StartBubble extends StatefulWidget {
  const _StartBubble();
  @override
  State<_StartBubble> createState() => _StartBubbleState();
}

class _StartBubbleState extends State<_StartBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -4 * math.sin(_c.value * math.pi)),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: dark ? Duo.green : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dark ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
        ),
        child: Text('START',
            style: duoFont(size: 13, weight: FontWeight.w900, color: dark ? Colors.white : Duo.green, spacing: 1)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final bool dark;
  _RingPainter(this.pct, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = 37.6;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = dark ? Duo.dBorder : Duo.border;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Duo.green;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * pct.clamp(0.0, 1.0), false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.pct != pct || old.dark != dark;
}

/// Circular node with Duo press effect (shadow shrinks on tap).
class _PressableNode extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color shadow;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _PressableNode({required this.child, required this.color, required this.shadow, required this.onTap, this.onLongPress});

  @override
  State<_PressableNode> createState() => _PressableNodeState();
}

class _PressableNodeState extends State<_PressableNode> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      onLongPress: widget.onLongPress == null ? null : () { setState(() => _down = false); widget.onLongPress!(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _down ? 6 : 0, 0),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.shadow, offset: Offset(0, _down ? 2 : 8))],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
