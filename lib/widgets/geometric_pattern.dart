import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A light geometric pattern (8-point stars, like Islamic tiles).
/// Use it behind a card, with a very faint color.
class GeometricPattern extends StatelessWidget {
  final Color color;
  final double tile;

  const GeometricPattern({super.key, required this.color, this.tile = 52});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _PatternPainter(color: color, tile: tile),
        size: Size.infinite,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  final double tile;

  const _PatternPainter({required this.color, required this.tile});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = 0; y < size.height + tile; y += tile) {
      for (double x = 0; x < size.width + tile; x += tile) {
        final center = Offset(x + tile / 2, y + tile / 2);
        _star(canvas, center, tile * 0.40, paint);
        // Small diamond where four tiles meet.
        _polygon(canvas, Offset(x, y), tile * 0.09, math.pi / 2, 4, paint);
      }
    }
  }

  /// 8-point star = two squares, one turned by 45 degrees.
  void _star(Canvas canvas, Offset center, double r, Paint paint) {
    _polygon(canvas, center, r, math.pi / 4, 4, paint);
    _polygon(canvas, center, r, 0, 4, paint);
    canvas.drawCircle(center, r * 0.28, paint);
  }

  void _polygon(
    Canvas canvas,
    Offset center,
    double r,
    double rotation,
    int sides,
    Paint paint,
  ) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = rotation + i * 2 * math.pi / sides;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.color != color || old.tile != tile;
}
