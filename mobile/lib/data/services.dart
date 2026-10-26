import 'dart:async' show Completer;
import 'dart:convert';
import 'dart:io' show File;
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' show SpeechToText;

/// Text-to-speech for Mandarin (zh-CN), normal & slow rates.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  String speed = 'normal';

  Future<void> init() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      _ready = true;
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.isEmpty || !_ready) return;
    try {
      await _tts.stop();
      await _tts.setSpeechRate(speed == 'slow' ? 0.3 : 0.5);
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Speak at the slow rate once (listening exercise "🐢" button).
  Future<void> speakSlow(String text) async {
    if (text.isEmpty || !_ready) return;
    try {
      await _tts.stop();
      await _tts.setSpeechRate(0.3);
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try { await _tts.stop(); } catch (_) {}
  }
}

/// Speech recognition for Mandarin practice (zh-CN) via speech_to_text.
/// Falls back gracefully (ok=false) when the device has no ASR — callers
/// should then offer self-check scoring.
class AsrService {
  dynamic _stt; // speech_to_text.SpeechToText, kept dynamic so tests/web don't hard-fail
  bool _tried = false;
  bool _avail = false;

  Future<bool> _ensure() async {
    if (_tried) return _avail;
    _tried = true;
    try {
      // lazy import to keep tests/headless safe
      final mod = await _load();
      if (mod == null) return false;
      _stt = mod;
      _avail = await _stt.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _avail = false;
    }
    return _avail;
  }

  Future<dynamic> _load() async {
    try {
      final m = await Future.sync(() => SpeechToText());
      return m;
    } catch (_) {
      return null;
    }
  }

  /// Listen once and return the best transcript, or null if unsupported/error.
  Future<String?> listenOnce(String locale) async {
    if (!await _ensure()) return null;
    String result = '';
    final done = Completer<void>();
    try {
      await _stt.listen(
        onResult: (r) {
          result = r.recognizedWords as String? ?? '';
          if (r.finalResult == true && !done.isCompleted) done.complete();
        },
        localeId: locale,
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
      );
      await done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
      await _stt.stop();
    } catch (_) {
      return null;
    }
    return result.isEmpty ? null : result;
  }

  Future<void> cancel() async {
    try { await _stt?.stop(); } catch (_) {}
  }

  /// Coverage match: ≥80% of target hanzi appear in order in the transcript.
  static bool matchHanzi(String heard, String target) {
    String hz(String s) => s.split('').where((c) {
          final r = c.runes.first;
          return r >= 0x4E00 && r <= 0x9FFF;
        }).join();
    final h = hz(heard), t = hz(target);
    if (h.isEmpty || t.isEmpty) return false;
    if (h == t) return true;
    var i = 0, hit = 0;
    for (final c in h.split('')) {
      while (i < t.length && t[i] != c) { i++; }
      if (i < t.length) { hit++; i++; }
    }
    return hit / t.length >= 0.8;
  }
}

/// Shared singleton — safe to use anywhere (init is lazy/idempotent).
final AsrService asrService = AsrService();

/// Short answer-feedback sounds, bundled locally.
class SfxService {
  final AudioPlayer _p = AudioPlayer();

  Future<void> play(String name) async {
    try {
      await _p.stop();
      await _p.play(AssetSource('audio/$name'), volume: 0.6);
    } catch (_) {}
  }

  void dispose() => _p.dispose();
}

/// Backup export/import — same JSON payload as the web version.
class BackupService {
  /// Returns true if the file was shared/saved.
  Future<bool> exportJson(Map<String, dynamic> payload, {String level = 'hsk2'}) async {
    final data = const JsonEncoder.withIndent('  ').convert(payload);
    final name = '$level-progress-${DateTime.now().toIso8601String().substring(0, 10)}.json';
    if (kIsWeb) return false;
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$name');
      await f.writeAsString(data);
      await Share.shareXFiles([XFile(f.path)], text: '${level.toUpperCase()} progress backup');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns decoded payload map or null.
  Future<Map<String, dynamic>?> importJson() async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb,
      );
      final file = r?.files.firstOrNull;
      if (file == null) return null;
      String text;
      if (kIsWeb) {
        text = utf8.decode(file.bytes!);
      } else {
        text = await File(file.path!).readAsString();
      }
      final j = jsonDecode(text);
      return j is Map<String, dynamic> ? j : null;
    } catch (_) {
      return null;
    }
  }
}
