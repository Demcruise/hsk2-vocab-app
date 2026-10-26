import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kunkwan_hsk2/data/app_state.dart';
import 'package:kunkwan_hsk2/data/content.dart';
import 'package:kunkwan_hsk2/data/services.dart';
import 'package:kunkwan_hsk2/ui/quiz_screen.dart';
import 'package:kunkwan_hsk2/ui/story_screen.dart';
import 'package:kunkwan_hsk2/ui/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pinyinPlain strips tone marks', () {
    expect(ContentRepository.pinyinPlain('ānquán'), 'anquan');
    expect(ContentRepository.pinyinPlain('nǐ hǎo'), 'ni hao');
  });

  test('level storage keys are separated', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppState();
    await s.load(prefs);
    expect(s.level, 'hsk2');
    expect(s.storageKey, 'khsk2');
    expect(s.known.isNotEmpty, true); // hsk2 seed

    await s.setLevel('hsk1');
    expect(s.level, 'hsk1');
    expect(s.storageKey, 'khsk1');
    expect(s.known.isEmpty, true); // hsk1 has no seed
    expect(s.prog.isEmpty, true);

    // mark a word (id 5 is NOT in the hsk2 seed) in hsk1, switch back — hsk2 untouched
    s.toggleKnown(5);
    await s.setLevel('hsk2');
    expect(s.isKnown(5), false);
    await s.setLevel('hsk1');
    expect(s.isKnown(5), true);
  });

  test('backup payload carries level key', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppState();
    await s.load(prefs);
    expect(s.payload()['app'], 'khsk2');
    await s.setLevel('hsk1');
    expect(s.payload()['app'], 'khsk1');
  });

  test('word-bank exercise helpers', () async {
    final repo = ContentRepository();
    await repo.load();
    expect(repo.levelSize('hsk1'), 300);
    expect(repo.levelSize('hsk2'), 770);

    // normAnswer ignores case + punctuation
    expect(ContentRepository.normAnswer('I like it.'), 'i like it');
    expect(ContentRepository.normAnswer('You  are,  right!'), 'you are right');

    // pickExerciseSentence prefers 3..12 English tokens
    final rnd = math.Random(1);
    final v = repo.vocab.firstWhere((x) => x.sentences.isNotEmpty);
    final s = repo.pickExerciseSentence(v, rnd);
    expect(v.sentences.contains(s), true);

    // bank = answer tokens + distractors, deduped vs answer
    final ans = ContentRepository.enTokens(s.en);
    final bank = repo.buildBank(ans, rnd);
    expect(bank.length, ans.length + 4);
    for (final t in ans) {
      expect(bank.contains(t), true);
    }

    // segmentHanzi finds multi-char vocab words
    final segs = repo.segmentHanzi(s.hanzi);
    expect(segs.isNotEmpty, true);
    expect(segs.map((e) => e.text).join(), s.hanzi);
  });

  test('skill counters, markKnown, mistakes pool, storyDone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppState();
    await s.load(prefs);
    final repo = ContentRepository();
    await repo.load();

    // wrong answers tracked per skill
    final v = repo.vocab[5];
    s.recordQuizAnswer(v, false, skill: 'listen');
    s.recordQuizAnswer(v, false, skill: 'write');
    s.recordQuizAnswer(v, false);
    expect(s.skillMiss('listen'), 1);
    expect(s.skillMiss('write'), 1);
    expect(s.skillMiss('speak'), 0);
    expect(s.mistakeIds(), contains(v.id));

    // markKnown → level 3 + known set
    s.markKnown(v.id);
    expect(s.isKnown(v.id), true);
    expect(s.wordLevel(v.id), 3);

    // story completion persisted
    s.finishStory('dasar');
    expect(s.storyDone, contains('dasar'));
    final p = s.payload();
    expect(p['st']['dasar'], true);

    // reload → persists
    final s2 = AppState();
    await s2.load(prefs);
    expect(s2.storyDone, contains('dasar'));
    expect(s2.isKnown(v.id), true);
  });

  test('topic filter builds topic-only quiz pool', () async {
    final repo = ContentRepository();
    await repo.load();
    for (final u in repo.units) {
      final pool = repo.vocab.where((v) => v.topic == u.key).toList();
      expect(pool.length, u.wordCount, reason: u.key);
      expect(pool.every((v) => v.topic == u.key), true);
    }
    // every word with stroke data is pickable for write exercises
    final w = repo.vocab.firstWhere((v) => repo.writeCharFor(v) != null);
    expect(repo.strokesFor(repo.writeCharFor(w)!) != null, true);
    // stories loaded for both levels
    expect(repo.stories.length, 14);
    repo.setLevel('hsk1');
    expect(repo.stories.length, 14);
    repo.setLevel('hsk2');
  });

  testWidgets('story screen emits first beat', (tester) async {
    final repo = ContentRepository();
    await tester.runAsync(() => repo.load());
    ContentRepositoryHolder.instance = repo;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppState();
    await s.load(prefs);
    final story = repo.stories.first;
    debugPrint('STORY: ${story.id} beats=${story.beats.length} cast=${story.cast.length}');
    expect(story.beats.isNotEmpty, true);

    await tester.pumpWidget(MaterialApp(
      home: StoryScreen(state: s, content: repo, sfx: SfxService(), tts: TtsService(), story: story),
    ));
    for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }
    expect(find.text('CONTINUE'), findsOneWidget);
    // first beat = narrate/say text rendered
    expect(find.text(story.beats.first.en), findsOneWidget);

    // advance 4 beats — each beat appends a widget; ListView unmounts
    // offscreen children, so verify _shown grew and the latest beat renders.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final st = tester.state<StoryScreenState>(find.byType(StoryScreen));
      expect(st.shownCount, i + 2, reason: 'beat $i');
    }
    // last emitted beat (idx 4) must be visible in the tree
    final last = story.beats[4];
    expect(find.text(last.t == 'check' ? last.en : last.py), findsWidgets, reason: last.t);
  });

  testWidgets('exercise: MC select → CHECK → CONTINUE, then word bank', (tester) async {
    final repo = ContentRepository();
    await tester.runAsync(() => repo.load());
    ContentRepositoryHolder.instance = repo;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppState();
    await s.load(prefs);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: QuizScreen(state: s, content: repo, sfx: SfxService(), tts: TtsService()),
        ),
      ),
    ));
    for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 50)); }

    final st = tester.state<QuizScreenState>(find.byType(QuizScreen));

    // progressive mix starts with recognition MC: hanzi→pinyin
    expect(st.debugType, QType.hz2py);
    expect(find.text('Choose the correct pinyin'), findsOneWidget);
    expect(find.text('∞'), findsOneWidget);
    expect(find.text('拼音'), findsOneWidget);

    // MC questions 1–3: select correct option → CHECK → CONTINUE
    for (var qi = 0; qi < 3; qi++) {
      final opts = st.debugOpts;
      final ai = st.debugAnsIdx;
      expect(opts.length, greaterThanOrEqualTo(4), reason: 'q$qi opts');
      expect(ai, isNonNegative);
      // CHECK disabled until an option is picked
      final check = find.text('CHECK');
      expect(check, findsOneWidget);
      await tester.tap(find.text(opts[ai]).first);
      await tester.pump();
      await tester.tap(check);
      await tester.pump();
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }
      expect(st.debugAnswered, true);
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      for (var i = 0; i < 6; i++) { await tester.pump(const Duration(milliseconds: 50)); }
    }

    // q4 = sentence word-bank exercise
    expect(st.debugType, QType.bank);
    expect(find.text('Translate this sentence'), findsOneWidget);
    final bank = st.debugBank;
    final answer = st.debugAnswer;
    final used = <int>{};
    for (final tok in answer) {
      var idx = -1;
      for (var i = 0; i < bank.length; i++) {
        if (!used.contains(i) && bank[i] == tok) { idx = i; break; }
      }
      expect(idx, isNonNegative, reason: 'bank is missing token "$tok"');
      used.add(idx);
      final f = find.byKey(Key('chip-bank-$idx'));
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pump();
    }

    await tester.tap(find.text('CHECK'));
    await tester.pump();
    for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 50)); }
    expect(st.debugAnswered, true);
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // flush confetti timers
  });
}
