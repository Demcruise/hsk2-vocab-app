import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

/// Content repository — loads bundled JSON, builds topic units, search/filter helpers.
/// Holds both HSK levels; [vocab]/[units]/[radicals] always reflect [level].
class ContentRepository {
  static const levels = {'hsk1': 'HSK 1', 'hsk2': 'HSK 2'};

  String level = 'hsk2';
  String get levelLabel => levels[level] ?? 'HSK 2';

  final Map<String, List<VocabWord>> _levelVocab = {};
  List<VocabWord> vocab = [];
  List<RadicalEntry> radicals = [];
  List<RadicalEntry> _radicalsHsk2 = [];
  Map<String, List<String>> hanzi = {}; // char -> [pinyin, def, radChar, radPinyin, radMeaning]
  List<Unit> units = [];
  Map<String, StrokeChar> hw = {}; // char -> stroke data (575 chars, shared across levels)
  final Map<String, List<Story>> _stories = {}; // level -> stories

  static const unitDefs = [
    ('dasar', 'Greetings & Essentials'),
    ('waktu', 'Numbers, Time & Measure'),
    ('orang', 'People & Family'),
    ('tubuh', 'Body, Health & Feelings'),
    ('makan', 'Food & Drink'),
    ('rumah', 'Home & Things'),
    ('sekolah', 'School & Work'),
    ('jalan', 'Places, Directions & Transport'),
    ('belanja', 'Shopping & Money'),
    ('hobi', 'Activities & Hobbies'),
    ('alam', 'Nature, Weather & Animals'),
    ('sifat', 'Traits & Description'),
    ('umum', 'Verbs & Common Words'),
    ('fungsi', 'Function Words & Grammar'),
  ];

  static const waveOffsets = [0.0, 46.0, 80.0, 46.0, 0.0, -46.0, -80.0, -46.0];

  static const unitIcons = {
    'dasar': '👋', 'waktu': '🕐', 'orang': '👨‍👩‍👧', 'tubuh': '🩺',
    'makan': '🍜', 'rumah': '🏠', 'sekolah': '🎓', 'jalan': '🧭',
    'belanja': '🛍️', 'hobi': '🎮', 'alam': '🌤️', 'sifat': '😊',
    'umum': '📦', 'fungsi': '🧩',
  };
  static const unitColors = {
    'dasar': 0xFF58CC02, 'waktu': 0xFF1CB0F6, 'orang': 0xFFFF9600, 'tubuh': 0xFFFF4B4B,
    'makan': 0xFFFFC800, 'rumah': 0xFFA560E8, 'sekolah': 0xFF2B70C9, 'jalan': 0xFFFF86D0,
    'belanja': 0xFFCE82FF, 'hobi': 0xFF4BB4E8, 'alam': 0xFF58CC02, 'sifat': 0xFFFF4B4B,
    'umum': 0xFF1CB0F6, 'fungsi': 0xFFA560E8,
  };

  Future<void> load() async {
    final v2 = jsonDecode(await rootBundle.loadString('assets/data/vocab.json')) as List;
    _levelVocab['hsk2'] = v2.map((e) => VocabWord.fromJson(e as Map<String, dynamic>)).toList();
    final v1 = jsonDecode(await rootBundle.loadString('assets/data/vocab_hsk1.json')) as List;
    _levelVocab['hsk1'] = v1.map((e) => VocabWord.fromJson(e as Map<String, dynamic>)).toList();
    final r = jsonDecode(await rootBundle.loadString('assets/data/radicals.json')) as List;
    _radicalsHsk2 = r.map((e) => RadicalEntry.fromJson(e as Map<String, dynamic>)).toList();
    final h = jsonDecode(await rootBundle.loadString('assets/data/hanzi.json')) as Map<String, dynamic>;
    hanzi = h.map((k, v) => MapEntry(k, (v as List).cast<String>()));
    try {
      final hwj = jsonDecode(await rootBundle.loadString('assets/data/hw.json')) as Map<String, dynamic>;
      hw = hwj.map((k, v) {
        // medians stored as [[x,y],...] pairs per stroke
        final meds = (v['m'] as List)
            .map((stroke) => (stroke as List)
                .map((p) => (((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()))
                .toList())
            .toList();
        return MapEntry(k, StrokeChar((v['s'] as List).cast<String>(), meds));
      });
    } catch (_) {}
    for (final lv in levels.keys) {
      try {
        final s = jsonDecode(await rootBundle.loadString('assets/data/stories_$lv.json')) as List;
        _stories[lv] = s.map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _stories[lv] = const [];
      }
    }
    setLevel(level);
  }

  List<Story> get stories => _stories[level] ?? const [];
  Story? storyFor(String topic) {
    for (final s in stories) {
      if (s.topic == topic || s.id == topic) return s;
    }
    return null;
  }

  /// First char of [v] that has stroke data (for writing exercises).
  String? writeCharFor(VocabWord v) {
    for (final c in v.hanzi.split('')) {
      if (hw.containsKey(c)) return c;
    }
    return null;
  }

  /// Stroke data for a single char (null if the char isn't in hw.json).
  StrokeChar? strokesFor(String ch) => hw[ch];

  int levelSize(String l) => _levelVocab[l]?.length ?? 0;

  /// Swap the active level: vocab list, radicals and units all change.
  void setLevel(String l) {
    if (!_levelVocab.containsKey(l)) return;
    level = l;
    vocab = _levelVocab[l]!;
    radicals = l == 'hsk2' ? _radicalsHsk2 : _deriveRadicals(vocab);
    _buildUnits();
  }

  /// HSK 1 has no bundled radical sheet — derive entries from the hanzi map.
  List<RadicalEntry> _deriveRadicals(List<VocabWord> words) {
    final map = <String, _RadAcc>{};
    for (final v in words) {
      for (final ch in v.hanzi.split('')) {
        final d = hanzi[ch];
        if (d == null || d.length < 3 || d[2].isEmpty) continue;
        final acc = map.putIfAbsent(d[2], () => _RadAcc(
              d[2],
              d.length > 3 ? d[3] : '',
              d.length > 4 ? d[4] : '',
            ));
        acc.chars.add(ch);
        acc.words.add(v.hanzi);
      }
    }
    final out = map.values
        .map((a) => RadicalEntry(
              radical: a.radical,
              variant: '',
              pinyin: a.pinyin,
              meaning: a.meaning,
              explanation: 'A radical appearing in HSK 1 vocabulary.',
              chars: a.chars.toList(),
              words: a.words.toList()..sort(),
            ))
        .toList()
      ..sort((a, b) => b.words.length - a.words.length);
    return out;
  }

  void _buildUnits() {
    units = unitDefs.asMap().entries.map((e) {
      final idx = e.key;
      final key = e.value.$1;
      final name = e.value.$2;
      final idxs = <int>[
        for (var i = 0; i < vocab.length; i++)
          if (vocab[i].topic == key) i
      ];
      final lessons = <Lesson>[];
      final count = (idxs.length + 9) ~/ 10;
      for (var i = 0; i < idxs.length; i += 10) {
        lessons.add(Lesson(
          unitKey: key,
          unitName: name,
          unitIndex: idx,
          lessonIndex: lessons.length,
          lessonCount: count,
          vocabIdx: idxs.sublist(i, i + 10 > idxs.length ? idxs.length : i + 10),
        ));
      }
      return Unit(key: key, name: name, lessons: lessons);
    }).where((u) => u.lessons.isNotEmpty).toList();
  }

  // ---- helpers ported from index.html ----
  static const _toneBase = {
    'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
    'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
    'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
    'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
    'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
    'ü': 'u', 'ǖ': 'u', 'ǘ': 'u', 'ǚ': 'u', 'ǜ': 'u',
  };

  static String pinyinPlain(String p) {
    final b = StringBuffer();
    for (final ch in p.toLowerCase().split('')) {
      b.write(_toneBase[ch] ?? ch);
    }
    return b.toString();
  }

  static String alphaOf(VocabWord v) {
    final s = pinyinPlain(v.pinyin);
    if (s.isEmpty) return '#';
    final c = s[0];
    return RegExp(r'[a-z]').hasMatch(c) ? c.toUpperCase() : '#';
  }

  /// Groups a word list A–Z by first pinyin letter (sorted).
  static List<MapEntry<String, List<VocabWord>>> alphaGroups(List<VocabWord> list) {
    final sorted = [...list]..sort((a, b) {
        final la = alphaOf(a), lb = alphaOf(b);
        if (la != lb) return la.compareTo(lb);
        return pinyinPlain(a.pinyin).compareTo(pinyinPlain(b.pinyin));
      });
    final order = <String>[];
    final groups = <String, List<VocabWord>>{};
    for (final v in sorted) {
      final l = alphaOf(v);
      (groups[l] ??= []).add(v);
      if (!order.contains(l)) order.add(l);
    }
    return order.map((l) => MapEntry(l, groups[l]!)).toList();
  }

  static bool matches(VocabWord v, String q) {
    if (q.isEmpty) return true;
    final lq = q.toLowerCase();
    return v.hanzi.contains(q) ||
        v.pinyin.toLowerCase().contains(lq) ||
        pinyinPlain(v.pinyin).contains(lq) ||
        v.meaning.toLowerCase().contains(lq);
  }

  // ---- word-bank exercise helpers ----
  static List<String> enTokens(String s) =>
      s.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  static String normAnswer(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[.,!?…();:—\-]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Pick one example sentence suitable for a word-bank exercise
  /// (prefer 3..12 English tokens; fall back to any).
  Sentence pickExerciseSentence(VocabWord v, math.Random rnd) {
    final ok = v.sentences.where((s) {
      final n = enTokens(s.en).length;
      return n >= 3 && n <= 12;
    }).toList();
    final pool = ok.isNotEmpty ? ok : v.sentences;
    return pool[rnd.nextInt(pool.length)];
  }

  /// Answer tokens + 3–4 distractor tokens from other words' sentences.
  List<String> buildBank(List<String> answer, math.Random rnd) {
    final ansN = answer.map(normAnswer).toSet();
    final pool = <String>[];
    final poolN = <String>{};
    var tries = 0;
    while (pool.length < 4 && tries < 80) {
      tries++;
      final w = vocab[rnd.nextInt(vocab.length)];
      final s2 = pickExerciseSentence(w, rnd);
      final tk = enTokens(s2.en);
      final t = tk[rnd.nextInt(tk.length)];
      final nt = normAnswer(t);
      if (t.length <= 12 && !ansN.contains(nt) && !poolN.contains(nt)) {
        pool.add(t);
        poolN.add(nt);
      }
    }
    return [...answer, ...pool]..shuffle(rnd);
  }

  /// Segments a hanzi sentence into (text, word) chunks via longest match
  /// against the active vocab list. Single chars stay plain text.
  List<({String text, VocabWord? word})> segmentHanzi(String sent) {
    final words = vocab.map((v) => v.hanzi).where((h) => h.length > 1).toList()
      ..sort((a, b) => b.length - a.length);
    final byHanzi = {for (final v in vocab) v.hanzi: v};
    final out = <({String text, VocabWord? word})>[];
    var i = 0;
    while (i < sent.length) {
      String? m;
      for (final w in words) {
        if (sent.startsWith(w, i)) { m = w; break; }
      }
      if (m != null) {
        out.add((text: m, word: byHanzi[m]));
        i += m.length;
      } else {
        // merge consecutive single chars
        final start = i;
        i++;
        while (i < sent.length && !words.any((w) => sent.startsWith(w, i))) {
          i++;
        }
        out.add((text: sent.substring(start, i), word: null));
      }
    }
    return out;
  }

  RadicalEntry? radicalFor(String hanziChar) {
    for (final r in radicals) {
      if (r.radical.length == 1 && hanziChar.contains(r.radical)) return r;
    }
    return null;
  }
}

class _RadAcc {
  final String radical;
  final String pinyin;
  final String meaning;
  final Set<String> chars = {};
  final Set<String> words = {};
  _RadAcc(this.radical, this.pinyin, this.meaning);
}
