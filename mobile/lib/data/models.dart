// Data models — mirrors the schema used by index.html / vocab_data.json.

class Sentence {
  final String hanzi;
  final String pinyin;
  final String en;
  const Sentence(this.hanzi, this.pinyin, this.en);

  factory Sentence.fromJson(List<dynamic> j) =>
      Sentence(j[0] as String, j[1] as String, j[2] as String);
}

class VocabWord {
  final int id;
  final String hanzi;
  final String traditional;
  final String pinyin;
  final String meaning;
  final String topic;
  final List<Sentence> sentences;

  const VocabWord({
    required this.id,
    required this.hanzi,
    required this.traditional,
    required this.pinyin,
    required this.meaning,
    required this.topic,
    required this.sentences,
  });

  factory VocabWord.fromJson(Map<String, dynamic> j) => VocabWord(
        id: j['id'] is int ? j['id'] as int : int.parse('${j['id']}'),
        hanzi: j['hanzi'] as String,
        traditional: (j['traditional'] ?? j['hanzi']) as String,
        pinyin: j['pinyin'] as String,
        meaning: j['meaning'] as String,
        topic: (j['topic'] ?? 'umum') as String,
        sentences: ((j['sentences'] ?? const []) as List)
            .map((e) => Sentence.fromJson(e as List))
            .toList(),
      );
}

class RadicalEntry {
  final String radical;
  final String variant;
  final String pinyin;
  final String meaning;
  final String explanation;
  final List<String> chars;
  final List<String> words;

  const RadicalEntry({
    required this.radical,
    required this.variant,
    required this.pinyin,
    required this.meaning,
    required this.explanation,
    required this.chars,
    required this.words,
  });

  factory RadicalEntry.fromJson(Map<String, dynamic> j) => RadicalEntry(
        radical: j['radical'] as String,
        variant: (j['variant'] ?? '') as String,
        pinyin: (j['pinyin'] ?? '') as String,
        meaning: (j['meaning'] ?? '') as String,
        explanation: (j['explanation'] ?? '') as String,
        chars: ((j['chars'] ?? const []) as List).cast<String>(),
        words: ((j['words'] ?? const []) as List).cast<String>(),
      );
}

/// Per-word study progress: l = level (0..3, >=3 mastered), c/w = correct/wrong
/// counts, ml/ms/mw = mistake counters per skill (listen/speak/write).
class WordProgress {
  double l;
  int c;
  int w;
  int ml;
  int ms;
  int mw;
  String t;
  WordProgress({this.l = 0, this.c = 0, this.w = 0, this.ml = 0, this.ms = 0, this.mw = 0, this.t = ''});

  factory WordProgress.fromJson(Map<String, dynamic> j) => WordProgress(
        l: (j['l'] ?? 0).toDouble(),
        c: (j['c'] ?? 0) as int,
        w: (j['w'] ?? 0) as int,
        ml: (j['ml'] ?? 0) as int,
        ms: (j['ms'] ?? 0) as int,
        mw: (j['mw'] ?? 0) as int,
        t: (j['t'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {'l': l, 'c': c, 'w': w, 'ml': ml, 'ms': ms, 'mw': mw, 't': t};
}

/// Stroke-order data for one hanzi character (from hanzi-writer-data bundle).
class StrokeChar {
  final List<String> strokes; // SVG path data per stroke
  final List<List<(double, double)>> medians; // centerline points per stroke
  const StrokeChar(this.strokes, this.medians);
  int get strokeCount => strokes.length;
}

/// Interactive story (Duolingo Stories style) — one per topic per level.
class StoryCast {
  final String key;
  final String name;
  final String emoji;
  const StoryCast(this.key, this.name, this.emoji);
  factory StoryCast.fromJson(Map<String, dynamic> j) =>
      StoryCast(j['key'] as String, j['name'] as String, j['emoji'] as String);
}

class StoryBeat {
  final String t; // narrate | say | check | blank | pick
  final String who;
  final String hz;
  final String py;
  final String en; // English text for narrate/check/blank/pick (say: unused)
  final bool ans; // for check
  final int ansIdx; // for blank
  final List<(String, String)> opts; // for blank: [hanzi,pinyin]
  final String target; // for pick
  const StoryBeat({
    required this.t,
    this.who = '',
    this.hz = '',
    this.py = '',
    this.en = '',
    this.ans = false,
    this.ansIdx = 0,
    this.opts = const [],
    this.target = '',
  });

  factory StoryBeat.fromJson(Map<String, dynamic> j) => StoryBeat(
        t: j['t'] as String,
        who: (j['who'] ?? '') as String,
        hz: (j['hz'] ?? '') as String,
        py: (j['py'] ?? '') as String,
        en: (j['en'] ?? j['idn'] ?? j['q'] ?? '') as String,
        ans: j['ans'] is bool ? j['ans'] as bool : false,
        ansIdx: j['ans'] is int ? j['ans'] as int : 0,
        opts: ((j['opts'] ?? const []) as List)
            .map((e) => (e[0] as String, e[1] as String))
            .toList(),
        target: (j['target'] ?? '') as String,
      );
}

class Story {
  final String id;
  final String topic;
  final String title;
  final String color;
  final List<StoryCast> cast;
  final List<StoryBeat> beats;
  const Story({required this.id, required this.topic, required this.title, required this.color, required this.cast, required this.beats});

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        topic: j['topic'] as String,
        title: j['title'] as String,
        color: (j['color'] ?? '#58CC02') as String,
        cast: ((j['cast'] ?? const []) as List).map((e) => StoryCast.fromJson(e as Map<String, dynamic>)).toList(),
        beats: ((j['beats'] ?? const []) as List).map((e) => StoryBeat.fromJson(e as Map<String, dynamic>)).toList(),
      );

  StoryCast castOf(String key) =>
      cast.firstWhere((c) => c.key == key, orElse: () => const StoryCast('?', '🙂', '?'));
}

/// A lesson node on the learn path (~10 words).
class Lesson {
  final String unitKey;
  final String unitName;
  final int unitIndex;
  final int lessonIndex; // index within unit
  final int lessonCount; // total lessons in unit
  final List<int> vocabIdx; // indices into ContentRepository.vocab
  const Lesson({
    required this.unitKey,
    required this.unitName,
    required this.unitIndex,
    required this.lessonIndex,
    required this.lessonCount,
    required this.vocabIdx,
  });
}

class Unit {
  final String key;
  final String name;
  final List<Lesson> lessons;
  const Unit({required this.key, required this.name, required this.lessons});
  int get wordCount => lessons.fold(0, (a, l) => a + l.vocabIdx.length);
}
