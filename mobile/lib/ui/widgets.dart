import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../data/services.dart';
import 'duo.dart';
import 'writing.dart';

/// Renders a Chinese sentence with tappable hanzi characters.
/// Tapping a char shows a tooltip card: pinyin, meaning, radical.
class HanziText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight weight;
  const HanziText(this.text, {super.key, this.fontSize = 16, this.weight = FontWeight.w700});

  static bool _isHanzi(String c) => c.runes.every((r) => r >= 0x4E00 && r <= 0x9FFF);

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chars.map((c) {
        if (!_isHanzi(c)) {
          return Text(c, style: duoFont(size: fontSize, weight: weight));
        }
        return GestureDetector(
          onTap: () => HanziTooltip.show(context, c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Duo.blue.withValues(alpha: .35), width: 1.5)),
            ),
            child: Text(c, style: duoFont(size: fontSize, weight: weight)),
          ),
        );
      }).toList(),
    );
  }
}

class HanziTooltip {
  /// Rich detail sheet: pinyin, meaning, radical, strokes, words using it,
  /// hear-it button and a direct writing-practice shortcut.
  static void show(BuildContext context, String ch) {
    final repo = ContentRepositoryHolder.instance;
    final d = repo.hanzi[ch];
    if (d == null) return;
    final cs = Theme.of(context).colorScheme;
    final strokes = repo.hw[ch];
    final uses = repo.vocab.where((v) => v.hanzi.contains(ch)).take(4).toList();
    final state = AppStateHolder.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(ch, style: duoFont(size: 44, weight: FontWeight.w800)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (d.isNotEmpty && d[0].isNotEmpty)
                    Text(d[0], style: duoFont(size: 16, weight: FontWeight.w800, color: Duo.blue)),
                  if (d.length > 1 && d[1].isNotEmpty)
                    Text(d[1], style: duoFont(size: 13, weight: FontWeight.w600, color: cs.onSurface.withValues(alpha: .7))),
                ]),
              ),
              GestureDetector(
                onTap: () => TtsServiceHolder.instance.speak(ch),
                child: const Icon(Icons.volume_up_rounded, size: 24, color: Duo.blue),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (d.length > 2 && d[2].isNotEmpty)
                _tag('Radical: ${d[2]}${d.length > 3 && d[3].isNotEmpty ? ' (${d[3]})' : ''}${d.length > 4 && d[4].isNotEmpty ? ' — ${d[4]}' : ''}'),
              if (strokes != null) _tag('${strokes.strokeCount} strokes'),
              if (uses.isNotEmpty) _tag('${uses.length} related words'),
            ]),
            if (uses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Used in:', style: duoFont(size: 12, weight: FontWeight.w900, color: Duo.textLight)),
              const SizedBox(height: 6),
              for (final v in uses) _useRow(ctx, v, state),
            ],
            if (strokes != null) ...[
              const SizedBox(height: 14),
              DuoButton.secondary(
                label: '✍️ Practice writing $ch',
                onTap: () {
                  Navigator.pop(ctx);
                  if (state != null) {
                    WritingScreen.open(ctx, state, repo, [ch], title: 'Write $ch');
                  }
                },
                wide: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Duo.blueLight.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(t, style: duoFont(size: 12, weight: FontWeight.w800, color: Duo.blueDark)),
      );

  static Widget _useRow(BuildContext ctx, VocabWord v, AppState? state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '${v.hanzi}  ', style: duoFont(size: 15, weight: FontWeight.w800)),
            TextSpan(text: v.pinyin, style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.blue)),
          ])),
        ),
        Text(v.meaning, style: duoFont(size: 11.5, weight: FontWeight.w600, color: Duo.textLight)),
        const SizedBox(width: 8),
        if (state != null)
          GestureDetector(
            onTap: () { state.markKnown(v.id); duoToast(ctx, '${v.hanzi} marked as known ✓'); },
            child: Icon(
              state.isKnown(v.id) ? Icons.check_circle : Icons.check_circle_outline_rounded,
              size: 22, color: Duo.green,
            ),
          ),
      ]),
    );
  }
}

/// Shared holders for app-wide singletons (set in main).
class ContentRepositoryHolder {
  static late ContentRepository instance;
}

class AppStateHolder {
  static AppState? instance;
}

class TtsServiceHolder {
  static late TtsService instance;
}

/// Full-screen confetti burst — call ConfettiOverlay.show(context).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  static void show(BuildContext context) {
    final ov = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => const ConfettiOverlay());
    ov.insert(entry);
    Future.delayed(const Duration(milliseconds: 3400), entry.remove);
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_P> _ps;
  static const _colors = [Duo.green, Duo.blue, Duo.amber, Duo.rose, Duo.purple, Duo.orange];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();
    final rnd = math.Random();
    _ps = List.generate(140, (i) => _P(
          x: rnd.nextDouble(),
          y: -0.05 - rnd.nextDouble() * .5,
          w: 6 + rnd.nextDouble() * 8,
          h: 8 + rnd.nextDouble() * 8,
          color: _colors[i % _colors.length],
          vy: .25 + rnd.nextDouble() * .4,
          vx: -.08 + rnd.nextDouble() * .16,
          r: rnd.nextDouble() * math.pi,
          vr: -.1 + rnd.nextDouble() * .2,
        ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_ps, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _P {
  double x, y, w, h, vy, vx, r, vr;
  Color color;
  _P({required this.x, required this.y, required this.w, required this.h, required this.color, required this.vy, required this.vx, required this.r, required this.vr});
}

class _ConfettiPainter extends CustomPainter {
  final List<_P> ps;
  final double t;
  _ConfettiPainter(this.ps, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      final x = (p.x + p.vx * t) * size.width;
      final y = (p.y + p.vy * t * 3) * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.r + p.vr * t * 20);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}

/// Duo-style toast (bottom center pill).
void duoToast(BuildContext context, String msg) {
  final ov = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF323232),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg, style: duoFont(size: 13, weight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ),
    ),
  );
  ov.insert(entry);
  Future.delayed(const Duration(milliseconds: 1900), entry.remove);
}
