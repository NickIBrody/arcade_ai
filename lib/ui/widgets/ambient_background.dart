import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Slow drifting aurora glow behind the whole app. Cheap: two blurred radial
/// blobs animated on a single repeating controller.
class AmbientBackground extends StatefulWidget {
  final Widget child;
  final double intensity;
  const AmbientBackground({super.key, required this.child, this.intensity = 1});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) =>
                  CustomPaint(painter: _AuroraPainter(_c.value, widget.intensity)),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final double intensity;
  _AuroraPainter(this.t, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    _blob(
      canvas,
      size,
      Offset(size.width * (0.25 + 0.12 * math.sin(a)),
          size.height * (0.18 + 0.06 * math.cos(a))),
      size.width * 0.9,
      AppColors.violetDeep.withValues(alpha: 0.32 * intensity),
    );
    _blob(
      canvas,
      size,
      Offset(size.width * (0.85 + 0.1 * math.cos(a * 0.8)),
          size.height * (0.8 + 0.07 * math.sin(a * 1.2))),
      size.width * 0.8,
      AppColors.violet.withValues(alpha: 0.20 * intensity),
    );
  }

  void _blob(Canvas canvas, Size size, Offset c, double r, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}
