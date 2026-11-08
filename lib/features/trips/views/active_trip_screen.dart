import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:wakeway/features/map/widgets/wake_map_view.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class ActiveTripScreen extends StatelessWidget {
  const ActiveTripScreen({
    super.key,
    required this.controller,
    required this.onStop,
  });
  final WakeWayViewModel controller;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => PopScope(
      canPop: !controller.isMonitoring,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trip in progress'),
          automaticallyImplyLeading: false,
          actions: [
            StatusPill(
              label: controller.isMonitoring ? 'Tracking' : 'Stopped',
              icon: Icons.gps_fixed_rounded,
              color: controller.isMonitoring
                  ? WakeColors.green
                  : WakeColors.red,
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WakeMapView(
                  controller: controller,
                  destination: controller.activeDestination,
                  selectedPoint: LatLng(
                    controller.alarmLatitude,
                    controller.alarmLongitude,
                  ),
                  alarmRadiusMeters: controller.radiusMeters,
                  height: 320,
                ),
                const SizedBox(height: 15),
                SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const IconTile(
                        icon: Icons.notifications_active_rounded,
                        color: WakeColors.blue,
                        background: WakeColors.blueSoft,
                        size: 50,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Distance to alarm point',
                              style: TextStyle(
                                color: WakeColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.formatDistance(
                                controller.distanceToAlarmMeters,
                              ),
                              style: const TextStyle(
                                color: WakeColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 23,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Alarm radius · ${controller.formatDistance(controller.radiusMeters.toDouble())}',
                              style: const TextStyle(
                                color: WakeColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                SurfaceCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      LabeledIconRow(
                        icon: Icons.location_on_rounded,
                        title:
                            controller.activeDestination?.name ?? 'Destination',
                        subtitle: controller.activeDestination?.address ?? '',
                        color: WakeColors.green,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: WakeColors.line),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _TripMetric(
                              icon: Icons.my_location_rounded,
                              title: 'GPS accuracy',
                              value: controller.currentPosition == null
                                  ? 'Waiting'
                                  : '± ${controller.currentPosition!.accuracy.round()} m',
                              color: WakeColors.blue,
                            ),
                          ),
                          Expanded(
                            child: _TripMetric(
                              icon: Icons.access_time_rounded,
                              title: 'Started',
                              value: controller.tripStartedAt == null
                                  ? '—'
                                  : TimeOfDay.fromDateTime(
                                      controller.tripStartedAt!,
                                    ).format(context),
                              color: WakeColors.green,
                            ),
                          ),
                          Expanded(
                            child: _TripMetric(
                              icon: Icons.notifications_active_outlined,
                              title: 'Alarm',
                              value: controller.isAlarmActive
                                  ? 'Ringing'
                                  : 'Armed',
                              color: WakeColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (controller.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.lastError!,
                    style: const TextStyle(color: WakeColors.red),
                  ),
                ],
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: WakeColors.greenSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: WakeColors.green,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Location monitoring is active while this trip is running.',
                          style: TextStyle(
                            color: WakeColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop trip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WakeColors.red,
                    minimumSize: const Size.fromHeight(51),
                    side: const BorderSide(color: Color(0xFFF2C9CA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: WakeColors.muted, fontSize: 9),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
