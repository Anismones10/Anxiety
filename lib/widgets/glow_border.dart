import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';

/// A soft light that slowly runs around the edge of its child (like a comet).
/// It stops by itself when the screen is covered by another page, and it is
/// not shown at all if the phone has "remove animations" turned on.
class GlowBorder extends StatefulWidget {
  final Widget child;
  final double radius;
  final Color color;

  /// Start position (0..1). Different values make cards shine at different times.
  final double phase;
  final Duration duration;

  const GlowBorder({
    super.key,
    required this.child,
    this.radius = 14,
    this.color = Colors.white,
    this.phase = 0,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<GlowBorder> createState() => _GlowBorderState();
}

class _GlowBorderState extends State<GlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _CometPainter(
          animation: _controller,
          phase: widget.phase,
          color: widget.color,
          radius: widget.radius,
        ),
        child: widget.child,
      ),
    );
  }
}

class _CometPainter extends CustomPainter {
  final Animation<double> animation;
  final double phase;
  final Color color;
  final double radius;

  _CometPainter({
    required this.animation,
    required this.phase,
    required this.color,
    required this.radius,
  }) : super(repaint: animation);

  // The path around the card is measured once and kept.
  Size? _size;
  PathMetric? _metric;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_size != size || _metric == null) {
      final rrect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1),
        Radius.circular(radius),
      );
      _metric = (Path()..addRRect(rrect)).computeMetrics().first;
      _size = size;
    }
    final metric = _metric!;
    final length = metric.length;
    final tail = length * 0.2; // length of the light
    final head = ((animation.value + phase) % 1.0) * length;

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    // The light is drawn in small pieces: the tail is faint, the head is bright.
    const steps = 16;
    for (var i = 0; i < steps; i++) {
      final a = head - tail + tail * i / steps;
      final b = head - tail + tail * (i + 1) / steps;
      final strength = (i + 1) / steps;
      line.color = color.withValues(alpha: 0.75 * strength * strength);
      glow.color = color.withValues(alpha: 0.16 * strength * strength);
      _drawRange(canvas, metric, length, a, b, glow);
      _drawRange(canvas, metric, length, a, b, line);
    }
  }

  /// Draws the part of the path from a to b (it can pass the start of the path).
  void _drawRange(
    Canvas canvas,
    PathMetric metric,
    double length,
    double a,
    double b,
    Paint paint,
  ) {
    var start = a % length;
    if (start < 0) start += length;
    final end = start + (b - a);
    if (end <= length) {
      canvas.drawPath(metric.extractPath(start, end), paint);
    } else {
      canvas.drawPath(metric.extractPath(start, length), paint);
      canvas.drawPath(metric.extractPath(0, end - length), paint);
    }
  }

  @override
  bool shouldRepaint(_CometPainter old) =>
      old.color != color || old.phase != phase || old.radius != radius;
}
