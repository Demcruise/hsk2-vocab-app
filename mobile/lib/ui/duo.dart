import 'package:flutter/material.dart';

/// Duolingo-style design tokens — same palette as the PWA reskin.
class Duo {
  Duo._();

  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF46A302);
  static const greenLight = Color(0xFFD7FFB8);
  static const blue = Color(0xFF1CB0F6);
  static const blueDark = Color(0xFF1899D6);
  static const blueLight = Color(0xFFDDF4FF);
  static const amber = Color(0xFFFFC800);
  static const amberDark = Color(0xFFE0A800);
  static const rose = Color(0xFFFF4B4B);
  static const roseDark = Color(0xFFEA2B2B);
  static const roseLight = Color(0xFFFFDFE0);
  static const orange = Color(0xFFFF9600);
  static const orangeDark = Color(0xFFE08600);
  static const purple = Color(0xFFCE82FF);
  static const border = Color(0xFFE5E5E5);
  static const bg = Color(0xFFFFFFFF);
  static const text = Color(0xFF4B4B4B);
  static const textLight = Color(0xFF777777);
  static const nodeOff = Color(0xFFE5E5E5);
  static const nodeOffShadow = Color(0xFFD4D4D4);

  // dark palette (matches PWA dark theme)
  static const dBg = Color(0xFF0F1519);
  static const dCard = Color(0xFF1B242A);
  static const dBorder = Color(0xFF2E3A41);
  static const dText = Color(0xFFE8EDEF);
  static const dTextLight = Color(0xFF9FB0B8);
  static const dHeader = Color(0xFF3D8A01);
}

TextStyle duoFont({double size = 15, FontWeight weight = FontWeight.w700, Color? color, double? height, double? spacing}) {
  return TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );
}

/// Chunky Duo button: filled, rounded 12px, 4px bottom border that "presses" on tap.
class DuoButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onTap;
  final bool wide;
  final bool small;
  final bool disabled;

  const DuoButton({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.color = Duo.green,
    Color? borderColor,
    this.textColor = Colors.white,
    this.onTap,
    this.wide = false,
    this.small = false,
    this.disabled = false,
  }) : borderColor = borderColor ?? const Color(0xFF46A302);

  const DuoButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.onTap,
    this.wide = false,
    this.small = false,
    this.disabled = false,
  })  : color = Colors.transparent,
        borderColor = Duo.border,
        textColor = Duo.blue;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _down = false;
  static const _press = 4.0;

  @override
  Widget build(BuildContext context) {
    final active = !widget.disabled && widget.onTap != null;
    final borderW = _down ? 2.0 : _press;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _down = true) : null,
      onTapUp: active ? (_) { setState(() => _down = false); widget.onTap!(); } : null,
      onTapCancel: active ? () => setState(() => _down = false) : null,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(0, _down ? _press - 2 : 0, 0),
        width: widget.wide ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: widget.small ? 12 : 18,
          vertical: widget.small ? 8 : 13,
        ),
        decoration: BoxDecoration(
          color: widget.color == Colors.transparent
              ? Theme.of(context).cardColor
              : (widget.disabled ? Duo.nodeOff : widget.color),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            top: BorderSide(color: widget.borderColor, width: 2),
            left: BorderSide(color: widget.borderColor, width: 2),
            right: BorderSide(color: widget.borderColor, width: 2),
            bottom: BorderSide(color: widget.borderColor, width: borderW),
          ),
        ),
        child: Row(
          mainAxisSize: widget.wide ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.emoji != null)
              Padding(padding: const EdgeInsets.only(right: 6), child: Text(widget.emoji!, style: TextStyle(fontSize: widget.small ? 13 : 15))),
            if (widget.icon != null)
              Padding(padding: const EdgeInsets.only(right: 6), child: Icon(widget.icon, size: widget.small ? 15 : 17, color: widget.textColor)),
            Flexible(
              child: Text(
                widget.label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: duoFont(
                  size: widget.small ? 12 : 14,
                  weight: FontWeight.w800,
                  color: widget.disabled ? Duo.textLight : widget.textColor,
                  spacing: .6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Duo card: border-2, radius 16, no shadow.
class DuoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const DuoCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
      ),
      child: child,
    );
    if (onTap == null) return c;
    return GestureDetector(onTap: onTap, child: c);
  }
}

/// Rounded progress bar (Duolingo green).
class DuoBar extends StatelessWidget {
  final double pct; // 0..1
  final double height;
  final Color? color;
  const DuoBar({super.key, required this.pct, this.height = 16, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: Theme.of(context).dividerColor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : const Duration(milliseconds: 300),
            width: double.infinity,
            height: height,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? Duo.green,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
