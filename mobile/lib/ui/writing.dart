import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import 'duo.dart';
import 'widgets.dart';

/// Tracing surface for one hanzi character, validated stroke-by-stroke
/// against the bundled hanzi-writer median data (offline).
///
/// Coordinate space: hanzi-writer uses a 1024 box with raw y flipped —
/// display y = 900 - rawY.
class StrokeTraceView extends StatefulWidget {
  final StrokeChar ch;
  final double size;
  final void Function(int mistakes) onComplete;
  final void Function(int mistakes)? onMistake;
  const StrokeTraceView({super.key, required this.ch, required this.size, required this.onComplete, this.onMistake});

  @override
  State<StrokeTraceView> createState() => StrokeTraceViewState();
}

class StrokeTraceViewState extends State<StrokeTraceView> {
  int _done = 0;
  int _mistakes = 0;
  int _missOnCur = 0;
  List<Offset> _cur = [];
  bool _finished = false;
  bool _showGhost = true;

  static const _rawBox = 1024.0;
  double get _scale => widget.size / _rawBox;
  Offset _m(double x, double y) => Offset(x * _scale, (900 - y) * _scale);

  List<Offset> _medianPts(int i) => widget.ch.medians[i].map((p) => _m(p.$1, p.$2)).toList();

  List<Offset> _resample(List<Offset> pts, int n) {
    if (pts.isEmpty) return const [];
    if (pts.length == 1) return List.filled(n, pts.first);
    final seg = <double>[0];
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      total += (pts[i] - pts[i - 1]).distance;
      seg.add(total);
    }
    if (total < 1) return List.filled(n, pts.first);
    final out = <Offset>[];
    var j = 0;
    for (var k = 0; k < n; k++) {
      final t = total * k / (n - 1);
      while (j < seg.length - 2 && seg[j + 1] < t) { j++; }
      final f = (t - seg[j]) / (seg[j + 1] - seg[j] + 1e-9);
      out.add(Offset.lerp(pts[j], pts[j + 1], f.clamp(0.0, 1.0))!);
    }
    return out;
  }

  double _meanDist(List<Offset> a, List<Offset> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) { s += (a[i] - b[i]).distance; }
    return s / a.length;
  }

  bool _judge(List<Offset> drawn) {
    if (drawn.length < 2) return false;
    final med = _medianPts(_done);
    final rU = _resample(drawn, 24), rM = _resample(med, 24);
    final box = widget.size;
    final startOk = (rU.first - rM.first).distance < box * .26;
    final endOk = (rU.last - rM.last).distance < box * .26;
    final devOk = _meanDist(rU, rM) < box * .17;
    return startOk && endOk && devOk;
  }

  void _endStroke() {
    if (_finished || _done >= widget.ch.strokeCount) return;
    final ok = _judge(_cur);
    setState(() {
      _cur = [];
      if (ok) {
        _done++;
        _missOnCur = 0;
        if (_done >= widget.ch.strokeCount) {
          _finished = true;
          widget.onComplete(_mistakes);
        }
      } else {
        _mistakes++;
        _missOnCur++;
        widget.onMistake?.call(_mistakes);
      }
    });
  }

  /// Reveal strokes one-by-one (tutorial "Tonton").
  Future<void> replay() async {
    setState(() { _done = 0; _finished = false; _showGhost = true; });
    for (var i = 0; i < widget.ch.strokeCount; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 650));
      setState(() => _done = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() { _done = 0; _finished = false; });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onPanStart: (d) => setState(() => _cur = [d.localPosition]),
      onPanUpdate: (d) => setState(() => _cur.add(d.localPosition)),
      onPanEnd: (_) => _endStroke(),
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _TracePainter(
          ch: widget.ch,
          toDisp: _m,
          done: _done,
          cur: _cur,
          dark: dark,
          hint: _missOnCur >= 2,
          showGhost: _showGhost && !_finished,
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final StrokeChar ch;
  final Offset Function(double x, double y) toDisp;
  final int done;
  final List<Offset> cur;
  final bool dark;
  final bool hint;
  final bool showGhost;
  _TracePainter({required this.ch, required this.toDisp, required this.done, required this.cur, required this.dark, required this.hint, required this.showGhost});

  Paint _line(Color c, double w) => Paint()
    ..color = c
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  Path _med(List<(double, double)> pts) {
    final p = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = toDisp(pts[i].$1, pts[i].$2);
      if (i == 0) { p.moveTo(o.dx, o.dy); } else { p.lineTo(o.dx, o.dy); }
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = (dark ? Duo.dBorder : Duo.border);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), grid);

    // ghost = all remaining strokes as fat translucent centerlines
    if (showGhost) {
      final gp = _line(dark ? const Color(0xFF3A4750) : const Color(0xFFE3E6E8), size.width * .09);
      for (var i = done; i < ch.strokeCount; i++) {
        canvas.drawPath(_med(ch.medians[i]), gp);
      }
    }
    // done strokes — solid
    final dp = _line(dark ? Duo.dText : Duo.text, size.width * .085);
    for (var i = 0; i < done && i < ch.strokeCount; i++) {
      canvas.drawPath(_med(ch.medians[i]), dp);
    }
    // hint arrow on current stroke after 2 misses
    if (hint && done < ch.strokeCount) {
      final m = ch.medians[done];
      final a = toDisp(m[0].$1, m[0].$2);
      final hp = _line(Duo.blue, size.width * .05);
      canvas.drawPath(_med(m), hp);
      final b = toDisp(m[1].$1, m[1].$2);
      final dir = (b - a).direction;
      canvas.drawCircle(a, 9, Paint()..color = Duo.blue);
      canvas.drawCircle(b + Offset(math.cos(dir), math.sin(dir)) * 6, 5, Paint()..color = Duo.blue);
    }
    // in-progress user stroke
    if (cur.length > 1) {
      final up = _line(Duo.blue, size.width * .055);
      final p = Path()..moveTo(cur.first.dx, cur.first.dy);
      for (final o in cur.skip(1)) { p.lineTo(o.dx, o.dy); }
      canvas.drawPath(p, up);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) =>
      old.done != done || old.cur.length != cur.length || old.hint != hint || old.showGhost != showGhost || old.dark != dark;
}

/// Full-screen "Writing Practice" — step-by-step tutorial + tracing per char.
class WritingScreen extends StatefulWidget {
  final AppState state;
  final ContentRepository content;
  final List<String> chars; // characters to practice
  final String title;
  const WritingScreen({super.key, required this.state, required this.content, required this.chars, this.title = 'Writing Practice'});

  static void open(BuildContext context, AppState state, ContentRepository content, List<String> chars, {String title = 'Writing Practice'}) {
    final ok = chars.where((c) => content.hw.containsKey(c)).toSet().toList().take(20).toList();
    if (ok.isEmpty) {
      duoToast(context, 'No stroke data available');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => WritingScreen(state: state, content: content, chars: ok, title: title),
    ));
  }

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  int _i = 0;
  GlobalKey<StrokeTraceViewState> _key = GlobalKey<StrokeTraceViewState>();
  String _info = 'Watch first, then write it yourself';

  void _go(int i) => setState(() {
        _i = i;
        _key = GlobalKey<StrokeTraceViewState>();
        _info = 'Watch first, then write it yourself';
      });

  @override
  Widget build(BuildContext context) {
    final ch = widget.chars[_i];
    final data = widget.content.hw[ch]!;
    final word = widget.content.vocab.where((v) => v.hanzi.contains(ch)).firstOrNull;
    final size = math.min(MediaQuery.sizeOf(context).width * .72, 300.0);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 16, 4),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded), color: Duo.textLight),
              Expanded(child: DuoBar(pct: (_i + 1) / widget.chars.length)),
              const SizedBox(width: 10),
              Text('${widget.title} • ${_i + 1}/${widget.chars.length}',
                  style: duoFont(size: 11, weight: FontWeight.w800, color: Duo.textLight)),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '「$ch」', style: duoFont(size: 20, weight: FontWeight.w900)),
                  if (word != null) TextSpan(text: '  ${word.pinyin} — ${word.meaning}', style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight)),
                ])),
              ),
              const SizedBox(height: 4),
              Center(child: Text('${data.strokeCount} strokes', style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight))),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                  ),
                  child: StrokeTraceView(key: _key, ch: data, size: size, onMistake: (m) {
                    setState(() => _info = 'Try again… ($m missed)');
                  }, onComplete: (m) {
                    setState(() => _info = m == 0 ? 'Perfect! 🎉' : 'Done — $m strokes missed');
                    if (m == 0) {
                      widget.state.addXP(2);
                    }
                    if (word != null && m > 0) {
                      widget.state.recordQuizAnswer(word, false, skill: 'write');
                    }
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(_info, style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight))),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: DuoButton.secondary(label: '▶ Watch the order', onTap: () { setState(() => _info = 'Watch the stroke order…'); _key.currentState?.replay(); })),
                const SizedBox(width: 10),
                Expanded(child: DuoButton.secondary(label: '↺ Redo', onTap: () => setState(() => _info = 'Try writing: follow the ghost'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DuoButton.secondary(label: '◀', onTap: _i > 0 ? () => _go(_i - 1) : null, disabled: _i <= 0)),
                const SizedBox(width: 10),
                Expanded(child: DuoButton(label: 'Next ▶', onTap: () {
                  if (_i < widget.chars.length - 1) { _go(_i + 1); } else { Navigator.pop(context); }
                })),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
