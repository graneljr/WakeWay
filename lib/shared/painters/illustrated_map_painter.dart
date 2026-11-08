import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/wake_colors.dart';

class IllustratedMapPainter extends CustomPainter {
  IllustratedMapPainter({required this.alarmPoint, required this.activeTrip});

  final Offset alarmPoint;
  final bool activeTrip;

  Offset point(Size s, double x, double y) => Offset(s.width * x, s.height * y);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    final bg = Paint()..color = WakeColors.map;
    canvas.drawRect(Offset.zero & size, bg);

    final park = Path()
      ..moveTo(size.width * .59, 0)
      ..lineTo(size.width * .84, 0)
      ..cubicTo(
        size.width * .93,
        size.height * .08,
        size.width * .88,
        size.height * .23,
        size.width * .73,
        size.height * .25,
      )
      ..cubicTo(
        size.width * .62,
        size.height * .24,
        size.width * .56,
        size.height * .13,
        size.width * .59,
        0,
      );
    canvas.drawPath(park, Paint()..color = const Color(0xFFDDEBD7));

    final river = Path()
      ..moveTo(size.width * 1.03, size.height * .31)
      ..cubicTo(
        size.width * .83,
        size.height * .39,
        size.width * 1.1,
        size.height * .53,
        size.width * .88,
        size.height * .66,
      )
      ..cubicTo(
        size.width * .79,
        size.height * .72,
        size.width * .91,
        size.height * .86,
        size.width * .80,
        size.height * 1.03,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFDCECEF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .14,
    );

    final smallRoad = Paint()
      ..color = const Color(0xFFFCFDFC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * .019
      ..strokeCap = StrokeCap.round;
    final minorRoads = <Path>[
      Path()
        ..moveTo(-.05 * size.width, .27 * size.height)
        ..cubicTo(
          .26 * size.width,
          .21 * size.height,
          .45 * size.width,
          .32 * size.height,
          .78 * size.width,
          .29 * size.height,
        ),
      Path()
        ..moveTo(-.04 * size.width, .58 * size.height)
        ..cubicTo(
          .22 * size.width,
          .52 * size.height,
          .59 * size.width,
          .61 * size.height,
          1.03 * size.width,
          .54 * size.height,
        ),
      Path()
        ..moveTo(.11 * size.width, -.05 * size.height)
        ..cubicTo(
          .20 * size.width,
          .28 * size.height,
          .14 * size.width,
          .63 * size.height,
          .25 * size.width,
          1.05 * size.height,
        ),
      Path()
        ..moveTo(.48 * size.width, -.05 * size.height)
        ..cubicTo(
          .37 * size.width,
          .24 * size.height,
          .59 * size.width,
          .61 * size.height,
          .48 * size.width,
          1.06 * size.height,
        ),
      Path()
        ..moveTo(.76 * size.width, -.03 * size.height)
        ..cubicTo(
          .67 * size.width,
          .27 * size.height,
          .82 * size.width,
          .61 * size.height,
          .65 * size.width,
          1.02 * size.height,
        ),
    ];
    for (final road in minorRoads) {
      canvas.drawPath(road, smallRoad);
      canvas.drawPath(
        road,
        Paint()
          ..color = const Color(0xFFE4E8E4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * .0028,
      );
    }

    final mainRoad = Path()
      ..moveTo(-.04 * size.width, .81 * size.height)
      ..cubicTo(
        .20 * size.width,
        .69 * size.height,
        .43 * size.width,
        .67 * size.height,
        .59 * size.width,
        .53 * size.height,
      )
      ..cubicTo(
        .77 * size.width,
        .38 * size.height,
        .84 * size.width,
        .31 * size.height,
        1.04 * size.width,
        .20 * size.height,
      );
    canvas.drawPath(
      mainRoad,
      Paint()
        ..color = const Color(0xFFD5D8D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .047
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      mainRoad,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .034
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      mainRoad,
      Paint()
        ..color = const Color(0xFFF1CF88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .004
        ..strokeCap = StrokeCap.round,
    );

    _drawLabel(
      canvas,
      'RIZAL PARK',
      point(size, .68, .13),
      size.width * .025,
      const Color(0xFF70916D),
    );
    _drawLabel(
      canvas,
      'MAKATI CITY',
      point(size, .20, .41),
      size.width * .027,
      const Color(0xFF7A8790),
    );
    _drawLabel(
      canvas,
      'AYALA AVE',
      point(size, .27, .76),
      size.width * .023,
      const Color(0xFF7A8790),
    );
    _drawLabel(
      canvas,
      'P. BURGOS ST',
      point(size, .73, .81),
      size.width * .021,
      const Color(0xFF7A8790),
    );

    final current = point(size, .23, .68);
    final dest = point(size, .80, .20);
    final alarm = point(
      size,
      alarmPoint.dx.clamp(.08, .92).toDouble(),
      alarmPoint.dy.clamp(.12, .88).toDouble(),
    );
    final route = Path()
      ..moveTo(current.dx, current.dy)
      ..cubicTo(
        size.width * .39,
        size.height * .57,
        size.width * .41,
        size.height * .71,
        alarm.dx,
        alarm.dy,
      )
      ..quadraticBezierTo(
        size.width * .70,
        size.height * .29,
        dest.dx,
        dest.dy,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .026
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = WakeColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .012
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      alarm,
      unit * .084,
      Paint()..color = WakeColors.red.withValues(alpha: .13),
    );
    canvas.drawCircle(alarm, unit * .046, Paint()..color = Colors.white);
    canvas.drawCircle(alarm, unit * .035, Paint()..color = WakeColors.red);
    canvas.drawCircle(
      current,
      unit * .06,
      Paint()..color = WakeColors.blue.withValues(alpha: .18),
    );
    canvas.drawCircle(current, unit * .028, Paint()..color = Colors.white);
    canvas.drawCircle(current, unit * .019, Paint()..color = WakeColors.blue);

    _drawPin(canvas, dest, unit * .075, WakeColors.green);
    if (activeTrip) {
      final halo = Paint()..color = WakeColors.blue.withValues(alpha: .1);
      canvas.drawCircle(current, unit * .14, halo);
      canvas.drawCircle(
        current,
        unit * .06,
        Paint()..color = WakeColors.blue.withValues(alpha: .2),
      );
    }
  }

  void _drawPin(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center.translate(0, -radius * .36),
      radius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center.translate(0, -radius * .36),
      radius * .75,
      Paint()..color = color,
    );
    canvas.drawCircle(
      center.translate(0, -radius * .36),
      radius * .28,
      Paint()..color = Colors.white,
    );
    final tail = Path()
      ..moveTo(center.dx - radius * .66, center.dy - radius * .15)
      ..lineTo(center.dx, center.dy + radius * .86)
      ..lineTo(center.dx + radius * .66, center.dy - radius * .15)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant IllustratedMapPainter oldDelegate) =>
      oldDelegate.alarmPoint != alarmPoint ||
      oldDelegate.activeTrip != activeTrip;
}
