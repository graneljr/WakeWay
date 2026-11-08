import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class GpsStatusScreen extends StatelessWidget {
  const GpsStatusScreen({super.key, required this.controller});

  final WakeWayViewModel controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final locationReady = controller.locationReady;
      return Scaffold(
        appBar: AppBar(title: const Text('GPS & permissions')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            children: [
              const PageHeading(
                'Ready for the road',
                subtitle: 'Check the device access WakeWay uses for a trip.',
              ),
              const SizedBox(height: 17),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 3,
                ),
                child: Column(
                  children: [
                    _PermissionRow(
                      icon: Icons.location_on_rounded,
                      title: 'Location permission',
                      detail: 'Needed to measure distance to your stop.',
                      status: controller.locationPermissionStatus,
                      ready: locationReady,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    _PermissionRow(
                      icon: Icons.gps_fixed_rounded,
                      title: 'GPS availability',
                      detail: controller.currentPosition == null
                          ? 'Turn on location services and check your signal.'
                          : 'Current accuracy ± ${controller.currentPosition!.accuracy.round()} m.',
                      status: controller.locationServicesEnabled
                          ? 'Ready'
                          : 'Off',
                      ready: controller.locationServicesEnabled,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    _PermissionRow(
                      icon: Icons.location_searching_rounded,
                      title: 'Trip tracking',
                      detail: 'Uses an Android foreground location notification while monitoring.',
                      status: controller.isMonitoring
                          ? 'Active'
                          : 'Ready at trip start',
                      ready: controller.isMonitoring || locationReady,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    _PermissionRow(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notifications',
                      detail: 'Shows proximity warnings and your alarm.',
                      status: controller.notificationsEnabled
                          ? 'Allowed'
                          : 'Not requested',
                      ready: controller.notificationsEnabled,
                    ),
                    const Divider(height: 1, color: WakeColors.line),
                    const _PermissionRow(
                      icon: Icons.volume_up_rounded,
                      title: 'Alarm audio',
                      detail: 'WakeWay plays a bundled sound when the alarm point is reached.',
                      status: 'Ready',
                      ready: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              if (controller.batteryTipsEnabled)
                const Text(
                  'WakeWay starts foreground location monitoring when you start a trip. Some Android devices may limit background work when battery saver is enabled.',
                  style: TextStyle(
                    color: WakeColors.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Check location access',
                icon: Icons.my_location_rounded,
                onPressed: () async {
                  try {
                    await controller.locateOnce();
                  } on Object catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: controller.requestNotificationPermission,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Allow notifications'),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: Geolocator.openAppSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open app settings'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.ready,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final bool ready;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: WakeColors.blue, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: WakeColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  color: WakeColors.muted,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: ready ? WakeColors.green : const Color(0xFFB27A25),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
