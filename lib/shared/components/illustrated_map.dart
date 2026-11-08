import 'package:flutter/material.dart';

import '../../core/theme/wake_colors.dart';
import '../painters/illustrated_map_painter.dart';
import 'status_pill.dart';

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
