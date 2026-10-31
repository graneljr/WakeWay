import 'dart:math' as math;

import 'package:flutter/material.dart';

class WakeColors {
  static const ink = Color(0xFF142D46);
  static const navy = Color(0xFF102A43);
  static const blue = Color(0xFF246FCB);
  static const blueSoft = Color(0xFFEAF2FF);
  static const green = Color(0xFF1F795C);
  static const greenSoft = Color(0xFFE8F5EF);
  static const red = Color(0xFFC8434E);
  static const redSoft = Color(0xFFFFECEC);
  static const canvas = Color(0xFFF4F7FA);
  static const line = Color(0xFFE7ECF1);
  static const muted = Color(0xFF5E6F81);
  static const map = Color(0xFFF0F2EC);
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A18334A),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: WakeColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.trailing, this.onTrailing});

  final String label;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (trailing != null)
        TextButton(
          onPressed: onTrailing,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 36),
          ),
          child: Text(trailing!),
        ),
    ],
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = WakeColors.blue,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.color = WakeColors.green,
    this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: background ?? color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: size * .52),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 54});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: WakeColors.navy,
            borderRadius: BorderRadius.circular(size * .27),
          ),
          child: CustomPaint(
            painter: BrandRoadPainter(),
            size: Size.square(size),
          ),
        ),
        Positioned(
          left: size * .13,
          top: size * .11,
          child: Icon(
            Icons.nightlight_round,
            color: const Color(0xFFFFD773),
            size: size * .27,
          ),
        ),
        Positioned(
          right: size * .13,
          top: size * .12,
          child: Icon(
            Icons.notifications_active_rounded,
            color: const Color(0xFFFF8C83),
            size: size * .23,
          ),
        ),
        Icon(Icons.location_on_rounded, color: Colors.white, size: size * .50),
        Positioned(
          bottom: size * .18,
          child: Container(
            width: size * .10,
            height: size * .10,
            decoration: const BoxDecoration(
              color: WakeColors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

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

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              icon: icon,
              color: color,
              background: color.withValues(alpha: .1),
              size: 40,
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: WakeColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: WakeColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class LabeledIconRow extends StatelessWidget {
  const LabeledIconRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.color = WakeColors.blue,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        IconTile(
          icon: icon,
          color: color,
          background: color.withValues(alpha: .09),
          size: 44,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: WakeColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: WakeColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
    return onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: row,
          );
  }
}

class IllustratedMap extends StatelessWidget {
  const IllustratedMap({
    super.key,
    this.height = 300,
    this.alarmPoint = const Offset(.58, .44),
    this.interactive = false,
    this.activeTrip = false,
    this.onPointChanged,
    this.showControls = false,
    this.zoom = 1,
    this.onZoomIn,
    this.onZoomOut,
    this.onLocate,
  });

  final double height;
  final Offset alarmPoint;
  final bool interactive;
  final bool activeTrip;
  final ValueChanged<Offset>? onPointChanged;
  final bool showControls;
  final double zoom;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.scale(
              scale: zoom,
              child: CustomPaint(
                painter: IllustratedMapPainter(
                  alarmPoint: alarmPoint,
                  activeTrip: activeTrip,
                ),
              ),
            ),
          ),
          if (interactive)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => onPointChanged?.call(
                    Offset(
                      details.localPosition.dx / constraints.maxWidth,
                      details.localPosition.dy / constraints.maxHeight,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          if (showControls)
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  _MapControl(icon: Icons.add_rounded, onTap: onZoomIn),
                  const SizedBox(height: 8),
                  _MapControl(icon: Icons.remove_rounded, onTap: onZoomOut),
                  const SizedBox(height: 8),
                  _MapControl(
                    icon: Icons.my_location_rounded,
                    color: WakeColors.blue,
                    onTap: onLocate,
                  ),
                ],
              ),
            ),
          Positioned(
            left: 12,
            top: 12,
            child: StatusPill(
              label: 'Offline ready',
              icon: Icons.offline_pin_rounded,
              color: WakeColors.green,
              background: Colors.white.withValues(alpha: .94),
            ),
          ),
          if (interactive)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'Tap to place alarm point',
                  style: TextStyle(
                    color: WakeColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.icon,
    this.color = WakeColors.ink,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    elevation: 2,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, color: color, size: 20),
      ),
    ),
  );
}

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
