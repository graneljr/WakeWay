import 'package:flutter/material.dart';

import '../../core/theme/wake_colors.dart';
import '../painters/brand_road_painter.dart';

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
