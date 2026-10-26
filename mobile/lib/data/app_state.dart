import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Central app state — ports the logic of index.html's S + save/load.
/// Persistence key & backup payload use the SAME schema as the web app,
/// so progress files are interchangeable between PWA and this app.
class AppState extends ChangeNotifier {
  static const levelKey = 'khsk-level';
  static const themeKey = 'khsk2-theme';

  /// Active level: 'hsk1' | 'hsk2'. Each level has its own storage key.
  String level = 'hsk2';
  String get levelLabel => level == 'hsk1' ? 'HSK 1' : 'HSK 2';
  String get storageKey => 'khsk${level.substring(3)}';
  Set<int> get _seed => level == 'hsk2' ? knownDefault.toSet() : <int>{};

  /// Words pre-marked as known (same seed list as the web app).
  static const knownDefault = [
    1, 2, 3, 4, 6, 10, 12, 15, 18, 21, 22, 30, 34, 35, 37, 41, 43, 48, 49, 60,
    68, 69, 70, 71, 72, 74, 76, 80, 84, 101, 104, 105, 106, 120, 125, 126, 128,
    133, 137, 140, 146, 148, 149, 156, 167, 171, 189, 190, 194, 195, 196, 214,
    223, 225, 226, 227, 231, 239, 246, 255, 258, 261, 266, 276, 290, 295, 300,
    301, 302, 306, 311, 318, 321, 322, 329, 331, 333, 334, 336, 337, 342, 347,
    351, 353, 357, 364, 368, 369, 370, 371, 372, 375, 376, 387, 391, 405, 408,
    409, 414, 416, 418, 430, 432, 433, 445, 459, 461, 463, 469, 479, 497, 499,
    509, 512, 515, 521, 523, 531, 535, 537, 538, 545, 547, 553, 561, 566, 570,
    572, 576, 588, 604, 608, 610, 631, 633, 634, 637, 638, 651, 657, 660, 668,
    669, 670, 671, 673, 674, 675, 681, 683, 687, 688, 700, 703, 704, 708, 714,
    717, 721, 728, 741, 751, 761, 762, 769
  ];

  final Map<int, WordProgress> prog = {};
  Set<int> known = {};
  int streak = 0;
  String last = '';
  int xp = 0;
  int quizzes = 0;
  final Map<String, bool> ach = {};
  final Set<String> storyDone = {};
  final Set<String> lessonsDone = {}; // 'ui_li' keys for finished path lessons
  String screen = 'learn';
  String mode = 'unmem';
  String vf = 'belum';
  String kf = 'belum';
  String speed = 'normal';
  int? wid;
  String savedAt = '';
  String theme = 'light'; // 'light' | 'dark' | 'system'
  bool exPinyin = true; // tampilkan pinyin di bubble exercise

  SharedPreferences? _prefs;
  VoidCallback? onToast;
  VoidCallback? onConfetti;

  String _pendingToast = '';
  String consumeToast() { final t = _pendingToast; _pendingToast = ''; return t; }
  void _toast(String m) { _pendingToast = m; onToast?.call(); }

  /// Same format as JS Date.toDateString() — e.g. "Sun Oct 26 2025" — but any
  /// stable per-day string works since it's only compared for equality.
  static String _dateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load(SharedPreferences prefs) async {
    _prefs = prefs;
    theme = prefs.getString(themeKey) ?? 'system';
    exPinyin = prefs.getBool('khsk-expinyin') ?? true;
    final lv = prefs.getString(levelKey) ?? '';
    if (lv == 'hsk1' || lv == 'hsk2') level = lv;
    _loadLevelData();
    notifyListeners();
  }

  /// Switch to another HSK level: saves nothing extra (state already saved),
  /// resets in-memory fields, then loads that level's own storage bucket.
  Future<void> setLevel(String l) async {
    if (l == level || (l != 'hsk1' && l != 'hsk2')) return;
    level = l;
    await _prefs?.setString(levelKey, l);
    _resetFields();
    _loadLevelData();
    _toast('Switched to $levelLabel');
    notifyListeners();
  }

  void _resetFields() {
    prog.clear();
    known = _seed;
    streak = 0;
    last = '';
    xp = 0;
    quizzes = 0;
    ach.clear();
    storyDone.clear();
    lessonsDone.clear();
    screen = 'learn';
    mode = 'unmem';
    vf = 'belum';
    kf = 'belum';
    wid = null;
  }

  void _loadLevelData() {
    known = _seed;
    final s = _prefs?.getString(storageKey);
    if (s != null) {
      try {
        final p = jsonDecode(s) as Map<String, dynamic>;
        _applyPayload(p);
      } catch (_) {}
    }
    // streak bookkeeping (same as web)
    final today = _dateStr(DateTime.now());
    if (last != today) {
      final yest = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      streak = (last == yest) ? streak + 1 : 1;
      last = today;
      save();
    }
  }

  Future<void> save() async {
    savedAt = _fmtNow();
    await _prefs?.setString(storageKey, jsonEncode(payload()));
    notifyListeners();
  }

  void saveTheme(String t) {
    theme = t;
    _prefs?.setString(themeKey, t);
    notifyListeners();
  }

  void toggleExPinyin() {
    exPinyin = !exPinyin;
    _prefs?.setBool('khsk-expinyin', exPinyin);
    notifyListeners();
  }

  /// Same payload as web progressPayload() — {v, app, p, s, l, x, q, a, k, ...}
  Map<String, dynamic> payload() => {
        'v': 2,
        'app': storageKey,
        'at': DateTime.now().toIso8601String(),
        'p': prog.map((k, v) => MapEntry('$k', v.toJson())),
        's': streak,
        'l': last,
        'x': xp,
        'q': quizzes,
        'a': ach,
        'k': {for (final e in known) '$e': 1},
        'sc': screen,
        'md': mode,
        'vf': vf,
        'kf': kf,
        'wid': wid,
        'st': {for (final s in storyDone) s: true},
        'ld': {for (final s in lessonsDone) s: true},
      };

  void _applyPayload(Map<String, dynamic> p) {
    prog.clear();
    (p['p'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      final id = int.tryParse(k);
      if (id != null) prog[id] = WordProgress.fromJson(v as Map<String, dynamic>);
    });
    streak = (p['s'] ?? 0) as int;
    last = (p['l'] ?? last) as String;
    xp = (p['x'] ?? 0) as int;
    quizzes = (p['q'] ?? 0) as int;
    ach
      ..clear()
      ..addAll((p['a'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v == true)));
    final k = p['k'];
    if (k is Map) {
      known = k.keys.map((e) => int.tryParse('$e')).whereType<int>().toSet();
    }
    if (p['sc'] is String) screen = p['sc'];
    if (p['md'] is String) mode = p['md'];
    if (p['vf'] is String) vf = p['vf'];
    if (p['kf'] is String) kf = p['kf'];
    wid = p['wid'] as int?;
    storyDone.clear();
    final st = p['st'];
    if (st is Map) {
      for (final k in st.keys) {
        if (st[k] == true) storyDone.add('$k');
      }
    }
    lessonsDone.clear();
    final ld = p['ld'];
    if (ld is Map) {
      for (final k in ld.keys) {
        if (ld[k] == true) lessonsDone.add('$k');
      }
    }
  }

  /// Import a backup payload (from file or pasted JSON).
  bool importPayload(Map<String, dynamic> p) {
    try {
      _applyPayload(p);
      last = _dateStr(DateTime.now());
      save();
      return true;
    } catch (_) {
      return false;
    }
  }

  void resetProgress() {
    prog.clear();
    streak = 1;
    last = _dateStr(DateTime.now());
    xp = 0;
    quizzes = 0;
    ach.clear();
    known = _seed;
    storyDone.clear();
    lessonsDone.clear();
    wid = null;
    save();
    _toast('Progress reset!');
  }

  static String _fmtNow() {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year} ${n.hour}:${n.minute.toString().padLeft(2, '0')}';
  }

  // ---- game logic (ported) ----
  double wordLevel(int id) => prog[id]?.l ?? 0;
  bool isKnown(int id) => known.contains(id);

  void addXP(int n) {
    xp += n;
    _toast('+$n XP');
    save();
  }

  void toggleKnown(int id) {
    if (!known.remove(id)) known.add(id);
    save();
  }

  void markGroup(Iterable<int> ids, bool on) {
    for (final id in ids) {
      if (on) { known.add(id); } else { known.remove(id); }
    }
    save();
  }

  /// Flashcard rating: 1 = sulit, 2 = baik, 3 = mudah (ported from rateCard).
  void rateCard(int id, int rating) {
    final p = prog.putIfAbsent(id, () => WordProgress());
    if (rating == 1) {
      p.l = (p.l - 1).clamp(0, 3);
      p.w++;
      _toast('Will appear more often');
    } else if (rating == 2) {
      p.l = (p.l + 1).clamp(0, 2);
      p.c++;
      addXP(5);
    } else {
      p.l = (p.l + 1).clamp(0, 3);
      p.c++;
      addXP(10);
      if (p.l >= 3) known.add(id);
    }
    p.t = DateTime.now().toIso8601String();
    save();
  }

  /// Quiz answer result: correct → +10XP & +0.5 level; wrong → w++ plus
  /// per-skill miss counter (skill: 'listen' | 'speak' | 'write' | null).
  void recordQuizAnswer(VocabWord v, bool correct, {String? skill}) {
    final p = prog.putIfAbsent(v.id, () => WordProgress());
    if (correct) {
      p.c++;
      p.l = (p.l + .5).clamp(0, 3);
      p.t = DateTime.now().toIso8601String();
      xp += 10;
      if (p.l >= 3) known.add(v.id);
    } else {
      p.w++;
      switch (skill) {
        case 'listen': p.ml++;
        case 'speak': p.ms++;
        case 'write': p.mw++;
      }
    }
    save();
  }

  /// Instant "sudah hafal" mark — used by the Hafal quick buttons.
  void markKnown(int id) {
    final p = prog.putIfAbsent(id, () => WordProgress());
    p.l = 3;
    p.t = DateTime.now().toIso8601String();
    known.add(id);
    save();
  }

  /// Mark a finished story + award XP once.
  void finishStory(String storyId, {int xpReward = 20}) {
    final first = storyDone.add(storyId);
    xp += xpReward;
    save();
    if (first) _toast('+$xpReward XP');
  }

  /// Mark a learn-path lesson node as completed (persists per level).
  void finishLesson(String key) {
    lessonsDone.add(key);
    save();
  }
  bool isLessonDone(String key) => lessonsDone.contains(key);

  /// Skill miss counters across all words (for the Practice Hub tiles).
  int skillMiss(String skill) {
    var n = 0;
    for (final p in prog.values) {
      n += switch (skill) { 'listen' => p.ml, 'speak' => p.ms, 'write' => p.mw, _ => 0 };
    }
    return n;
  }

  /// Words the user got wrong anywhere (general w or skill counters).
  List<int> mistakeIds() => [
        for (final e in prog.entries)
          if (e.value.w > 0 || e.value.ml > 0 || e.value.ms > 0 || e.value.mw > 0) e.key
      ];

  int finishQuizXp(int pct) {
    final bonus = pct >= 80 ? 20 : (pct >= 60 ? 10 : 5);
    quizzes++;
    xp += bonus;
    save();
    return bonus;
  }

  // ---- derived stats ----
  int get masteredCount => prog.values.where((p) => p.l >= 3).length;
  int get learningCount => prog.values.where((p) => p.l >= 1 && p.l < 3).length;
  int get recordedCount => prog.length;

  /// Mode-filtered vocab indices (ported from applyMode).
  List<int> cardList(List<VocabWord> vocab) {
    final out = <int>[];
    for (var i = 0; i < vocab.length; i++) {
      final v = vocab[i];
      final l = wordLevel(v.id);
      final k = isKnown(v.id);
      final ok = switch (mode) {
        'all' => true,
        'new' => l == 0,
        'learning' => l >= 1 && l < 3,
        'review' => l >= 1,
        'mastered' => l >= 3,
        'unmem' => !k,
        'known' => k,
        _ => true,
      };
      if (ok) out.add(i);
    }
    if (out.isEmpty && mode != 'all') {
      mode = 'all';
      return cardList(vocab);
    }
    return out;
  }

  // ---- achievements (ported defs) ----
  List<({String id, String name, String desc, String emoji, bool unlocked})> achievements(int total) {
    bool u(String id, bool cond) {
      final have = ach[id] ?? cond;
      if (have && ach[id] != true) ach[id] = true;
      return have;
    }
    return [
      (id: 'fv', name: 'First Steps', desc: '1 word', emoji: '🌱', unlocked: u('fv', prog.isNotEmpty)),
      (id: 'tv', name: 'Beginner', desc: '10 words', emoji: '🌿', unlocked: u('tv', prog.length >= 10)),
      (id: 'fiv', name: 'Diligent', desc: '50 words', emoji: '🌳', unlocked: u('fiv', prog.length >= 50)),
      (id: 'hv', name: 'Collector', desc: '100 words', emoji: '🏅', unlocked: u('hv', prog.length >= 100)),
      (id: 'mv', name: 'Master $levelLabel', desc: '$total words', emoji: '👑', unlocked: u('mv', prog.values.where((p) => p.l >= 1).length >= total)),
      (id: 'fq', name: 'First Quiz', desc: '1 quiz', emoji: '📝', unlocked: u('fq', quizzes >= 1)),
      (id: 's7', name: 'Consistent', desc: '7-day streak', emoji: '💪', unlocked: u('s7', streak >= 7)),
      (id: 'x5', name: '500 XP', desc: '500 XP', emoji: '🌟', unlocked: u('x5', xp >= 500)),
    ];
  }

  List<({String icon, String name, int cur, int goal})> get quests => [
        (icon: '🔥', name: 'Keep a 7-day streak', cur: streak, goal: 7),
        (icon: '✨', name: 'Collect 500 XP', cur: xp, goal: 500),
        (icon: '⭐', name: 'Master 100 words', cur: masteredCount, goal: 100),
      ];
}
