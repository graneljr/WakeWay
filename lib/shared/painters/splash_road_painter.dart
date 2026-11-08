import 'package:flutter/material.dart';

class SplashRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFEAF0F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .05, size.height * .83)
      ..cubicTo(
        size.width * .33,
        size.height * .62,
        size.width * .53,
        size.height * .92,
        size.width * .78,
        size.height * .68,
      )
      ..cubicTo(
        size.width * .94,
        size.height * .52,
        size.width * .86,
        size.height * .42,
        size.width * 1.05,
        size.height * .32,
      );
    canvas.drawPath(path, road);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .24),
      3,
      Paint()..color = const Color(0xFFE7EDF2),
    );
    canvas.drawCircle(
      Offset(size.width * .17, size.height * .20),
      2,
      Paint()..color = const Color(0xFFE7EDF2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
