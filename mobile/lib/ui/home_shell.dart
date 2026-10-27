import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/services.dart';
import 'duo.dart';
import 'learn_screen.dart';
import 'vocab_screen.dart';
import 'quiz_picker.dart';
import 'radicals_screen.dart';
import 'progress_screen.dart';
import 'widgets.dart';

/// App shell: green top bar + 6-tab bottom navigation (Duolingo mobile style).
/// On wide screens (>=1024) swaps bottom nav for a left sidebar.
class HomeShell extends StatefulWidget {
  final AppState state;
  final ContentRepository content;
  final TtsService tts;
  final SfxService sfx;
  final BackupService backup;

  const HomeShell({super.key, required this.state, required this.content, required this.tts, required this.sfx, required this.backup});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _tabs = ['learn', 'vocab', 'known', 'quiz', 'radicals', 'progress'];

  AppState get S => widget.state;
  ContentRepository get R => widget.content;

  int get _idx => _tabs.indexOf(S.screen).clamp(0, _tabs.length - 1);

  void _go(String s) {
    S.screen = s;
    S.save();
    setState(() {});
  }

  Future<void> _switchLevel([String? to]) async {
    final next = to ?? (R.level == 'hsk1' ? 'hsk2' : 'hsk1');
    if (next == R.level) return;
    await S.setLevel(next);
    R.setLevel(next);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    S.onToast = () {
      final m = S.consumeToast();
      if (m.isNotEmpty && mounted) duoToast(context, m);
    };
  }

  void _toggleTheme() {
    final darkNow = Theme.of(context).brightness == Brightness.dark;
    S.saveTheme(darkNow ? 'light' : 'dark');
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final screens = [
      LearnScreen(state: S, content: R, tts: widget.tts, sfx: widget.sfx, onSwitchLevel: _switchLevel),
      VocabScreen(state: S, content: R, knownTab: false),
      VocabScreen(state: S, content: R, knownTab: true),
      QuizPickerScreen(state: S, content: R, tts: widget.tts, sfx: widget.sfx),
      RadicalsScreen(state: S, content: R, onJumpWord: _jumpWord),
      ProgressScreen(state: S, content: R, backup: widget.backup, tts: widget.tts, sfx: widget.sfx),
    ];

    final feed = AnimatedSwitcher(
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : const Duration(milliseconds: 150),
      child: KeyedSubtree(key: ValueKey(S.screen), child: screens[_idx]),
    );

    return Scaffold(
      body: wide ? _wideLayout(dark, feed) : _mobileLayout(dark, feed),
      bottomNavigationBar: wide ? null : _bottomNav(dark),
    );
  }

  void _jumpWord(String hanzi) {
    final i = R.vocab.indexWhere((v) => v.hanzi == hanzi);
    if (i < 0) return;
    _go('learn');
    LearnScreen.openWord(context, R, S, widget.tts, widget.sfx, i);
  }

  // ---------- mobile ----------
  Widget _mobileLayout(bool dark, Widget feed) {
    return Column(children: [
      Container(
        color: dark ? Duo.dHeader : Duo.green,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, left: 14, right: 14, bottom: 10),
        child: SizedBox(
          height: 40,
          child: Row(children: [
            SvgPicture.asset('assets/svg/cn.svg', width: 26, height: 19),
            const SizedBox(width: 8),
            Text('Kunkwan', style: duoFont(size: 16, weight: FontWeight.w900, color: Colors.white)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _switchLevel(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white.withValues(alpha: .45), width: 1.5),
                ),
                child: Text(R.levelLabel, style: duoFont(size: 11, weight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const Spacer(),
            _hud('🔥', '${S.streak}'),
            const SizedBox(width: 12),
            _hud('✨', '${S.xp}'),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _toggleTheme,
              child: Text(dark ? '☀️' : '🌙', style: const TextStyle(fontSize: 18)),
            ),
          ]),
        ),
      ),
      Expanded(child: feed),
    ]);
  }

  Widget _hud(String emoji, String val) => Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 3),
        Text(val, style: duoFont(size: 14, weight: FontWeight.w900, color: const Color(0xFFFFD900))),
      ]);

  Widget _bottomNav(bool dark) {
    const items = [
      ('learn', Icons.home_rounded, 'Learn'),
      ('vocab', Icons.menu_book_rounded, 'Vocab'),
      ('known', Icons.check_circle_rounded, 'Known'),
      ('quiz', Icons.bolt_rounded, 'Quiz'),
      ('radicals', Icons.grid_view_rounded, 'Radicals'),
      ('progress', Icons.emoji_events_rounded, 'Progress'),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 2)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom, top: 6),
      child: Row(
        children: items.map((it) {
          final active = S.screen == it.$1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _go(it.$1),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: active ? Duo.blueLight.withValues(alpha: dark ? .15 : 1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(it.$2, size: 24, color: active ? Duo.blueDark : Duo.textLight),
                ),
                Text(
                  it.$3,
                  style: duoFont(size: 10, weight: FontWeight.w800, color: active ? Duo.blueDark : Duo.textLight),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- wide ----------
  Widget _wideLayout(bool dark, Widget feed) {
    const items = [
      ('learn', Icons.home_rounded, 'LEARN'),
      ('vocab', Icons.menu_book_rounded, 'VOCAB'),
      ('known', Icons.check_circle_rounded, 'KNOWN'),
      ('quiz', Icons.bolt_rounded, 'QUIZ'),
      ('radicals', Icons.grid_view_rounded, 'RADICALS'),
      ('progress', Icons.emoji_events_rounded, 'PROGRESS'),
    ];
    return Row(children: [
      Container(
        width: 250,
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 2))),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SvgPicture.asset('assets/svg/mascot.svg', width: 38, height: 38),
            const SizedBox(width: 8),
            Text('Kunkwan ', style: duoFont(size: 17, weight: FontWeight.w900, color: Duo.green)),
            GestureDetector(
              onTap: () => _switchLevel(),
              child: Text(R.levelLabel, style: duoFont(size: 17, weight: FontWeight.w900, color: Duo.blue)),
            ),
          ]),
          const SizedBox(height: 8),
          // level selector (desktop sidebar)
          Row(children: [
            for (final lv in const ['hsk1', 'hsk2']) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchLevel(lv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: R.level == lv ? Duo.green : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: R.level == lv ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${lv == 'hsk1' ? '🐣' : '🚀'} ${ContentRepository.levels[lv]}',
                        style: duoFont(size: 12, weight: FontWeight.w900, color: R.level == lv ? Colors.white : Duo.textLight),
                      ),
                    ),
                  ),
                ),
              ),
              if (lv == 'hsk1') const SizedBox(width: 8),
            ],
          ]),
          const SizedBox(height: 18),
          ...items.map((it) {
            final active = S.screen == it.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => _go(it.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: active ? Duo.greenLight.withValues(alpha: dark ? .15 : 1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: active ? Border.all(color: Duo.green, width: 2) : null,
                  ),
                  child: Row(children: [
                    Icon(it.$2, size: 22, color: active ? Duo.greenDark : Duo.textLight),
                    const SizedBox(width: 10),
                    Text(it.$3, style: duoFont(size: 13, weight: FontWeight.w900, color: active ? Duo.greenDark : Duo.textLight, spacing: .8)),
                    const Spacer(),
                    if (active) const Icon(Icons.chevron_right, size: 18, color: Duo.greenDark),
                  ]),
                ),
              ),
            );
          }),
          const Spacer(),
          DuoButton.secondary(
            label: dark ? 'Light Mode' : 'Dark Mode',
            emoji: dark ? '☀️' : '🌙',
            onTap: _toggleTheme,
            wide: true,
          ),
        ]),
      ),
      Expanded(child: feed),
      // right rail
      Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: ListView(children: [
          DuoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              SvgPicture.asset('assets/svg/cn.svg', width: 24, height: 17),
              const SizedBox(width: 6),
              Text(R.levelLabel, style: duoFont(size: 13, weight: FontWeight.w900)),
              const Spacer(),
              _hud('🔥', '${S.streak}'),
              const SizedBox(width: 12),
              _hud('✨', '${S.xp}'),
              const SizedBox(width: 12),
              SvgPicture.asset('assets/svg/heart.svg', width: 20, height: 20),
              Text(' ∞', style: duoFont(size: 13, weight: FontWeight.w900, color: Duo.rose)),
            ]),
          ),
          const SizedBox(height: 14),
          DuoCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MISSIONS', style: duoFont(size: 13, weight: FontWeight.w900, color: Duo.textLight, spacing: 1)),
              const SizedBox(height: 10),
              ...S.quests.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Text(q.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(q.name, style: duoFont(size: 13, weight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Stack(children: [
                            DuoBar(pct: q.cur / q.goal, height: 12),
                            Positioned.fill(
                              child: Center(child: Text('${q.cur > q.goal ? q.goal : q.cur}/${q.goal}', style: duoFont(size: 9, weight: FontWeight.w900, color: Colors.white))),
                            ),
                          ]),
                        ]),
                      ),
                    ]),
                  )),
            ]),
          ),
          const SizedBox(height: 14),
          DuoCard(
            child: Column(children: [
              SvgPicture.asset('assets/svg/mascot.svg', width: 64, height: 64),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: Text('BACK UP YOUR PROGRESS', style: duoFont(size: 13, weight: FontWeight.w900))),
              const SizedBox(height: 4),
              Text('Save a progress file so it\u2019s safe to move devices.', style: duoFont(size: 12, weight: FontWeight.w600, color: Duo.textLight)),
              const SizedBox(height: 10),
              DuoButton.secondary(
                label: 'Save to File',
                onTap: () async {
                  final ok = await widget.backup.exportJson(S.payload(), level: S.level);
                  if (mounted) duoToast(context, ok ? 'Progress saved!' : 'Failed to save file');
                },
                wide: true,
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
