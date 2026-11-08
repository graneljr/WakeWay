import 'package:flutter/material.dart';

class BrandRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF40627E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .055
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .94)
      ..cubicTo(
        size.width * .36,
        size.height * .62,
        size.width * .48,
        size.height * .95,
        size.width * .79,
        size.height * .61,
      )
      ..cubicTo(
        size.width * .89,
        size.height * .49,
        size.width * .91,
        size.height * .38,
        size.width * .92,
        size.height * .30,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
