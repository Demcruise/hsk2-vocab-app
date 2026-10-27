import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Animated isometric sticker — plays a horizontal sprite sheet exported
/// from the fun-isometric kit (stickers/ in the repo root).
/// Honors [MediaQuery.disableAnimations] by pinning [stillFrame].
class FiSticker extends StatefulWidget {
  final String asset;
  final int frames;
  final int cell;
  final int stillFrame;
  final bool loop;
  final double size;

  const FiSticker({
    super.key,
    required this.asset,
    required this.frames,
    required this.stillFrame,
    this.cell = 160,
    this.loop = true,
    this.size = 140,
  });

  const FiSticker.loupe({super.key, this.size = 140})
      : asset = 'assets/stickers/loupe.png',
        frames = 45,
        cell = 160,
        stillFrame = 10,
        loop = true;

  const FiSticker.sprout({super.key, this.size = 140})
      : asset = 'assets/stickers/sprout.png',
        frames = 45,
        cell = 160,
        stillFrame = 23,
        loop = true;

  const FiSticker.tile({super.key, this.size = 140})
      : asset = 'assets/stickers/tile.png',
        frames = 42,
        cell = 160,
        stillFrame = 21,
        loop = true;

  const FiSticker.medal({super.key, this.size = 170})
      : asset = 'assets/stickers/medal.png',
        frames = 25,
        cell = 160,
        stillFrame = 23,
        loop = false;

  @override
  State<FiSticker> createState() => _FiStickerState();
}

class _FiStickerState extends State<FiSticker> {
  ui.Image? _img;
  Timer? _timer;
  int _frame = 0;
  bool _noAnim = false;

  @override
  void initState() {
    super.initState();
    rootBundle.load(widget.asset).then((d) async {
      final img = await decodeImageFromList(d.buffer.asUint8List());
      if (!mounted) return;
      setState(() {
        _img = img;
        _syncTimer();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _noAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (_noAnim || _img == null) {
      _frame = widget.stillFrame;
      return;
    }
    // sheets are sampled every 4th source frame -> 15fps playback
    _timer = Timer.periodic(const Duration(milliseconds: 66), (_) {
      if (!mounted) return;
      setState(() {
        if (widget.loop) {
          _frame = (_frame + 1) % widget.frames;
        } else if (_frame < widget.frames - 1) {
          _frame++;
        } else {
          _frame = widget.stillFrame;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _img;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: img == null
          ? const SizedBox.shrink()
          : CustomPaint(painter: _FiPainter(img, _frame, widget.cell)),
    );
  }
}

class _FiPainter extends CustomPainter {
  final ui.Image img;
  final int frame;
  final int cell;
  _FiPainter(this.img, this.frame, this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(frame * cell.toDouble(), 0, cell.toDouble(), cell.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_FiPainter old) => old.frame != frame || old.img != img;
}
