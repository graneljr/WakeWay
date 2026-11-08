import 'package:flutter/material.dart';

class HeroRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFF35536F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-4, size.height * .9)
      ..cubicTo(
        size.width * .36,
        size.height * .17,
        size.width * .4,
        size.height * 1.12,
        size.width * .92,
        size.height * .25,
      );
    canvas.drawPath(path, road);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7693AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    final dashes = Paint()
      ..color = const Color(0xFF7693AB)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (.17 + i * .16),
          size.height * (.65 - (i % 3) * .1),
        ),
        1.5,
        dashes,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
