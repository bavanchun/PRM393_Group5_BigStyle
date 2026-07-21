import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_motion.dart';

/// Draws an animated checkmark (ring stroke + check stroke) via
/// CustomPainter, with a scale-in entrance — no Lottie/asset dependency.
class AnimatedSuccessCheck extends StatefulWidget {
  final double size;

  const AnimatedSuccessCheck({super.key, this.size = 64});

  @override
  State<AnimatedSuccessCheck> createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<AnimatedSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow)
      ..forward();
    _scale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ScaleTransition(
          scale: _scale,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _CheckPainter(progress: _controller.value),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;

  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final ringProgress = (progress / 0.6).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -1.5708,
      6.28319 * ringProgress,
      false,
      ringPaint,
    );

    final checkProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    if (checkProgress <= 0) return;

    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.34);

    final firstLegLength = (p2 - p1).distance;
    final totalLength = firstLegLength + (p3 - p2).distance;
    final drawnLength = totalLength * checkProgress;

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (drawnLength <= firstLegLength) {
      final t = drawnLength / firstLegLength;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final secondLegLength = (p3 - p2).distance;
      final t = ((drawnLength - firstLegLength) / secondLegLength).clamp(
        0.0,
        1.0,
      );
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    final checkPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
