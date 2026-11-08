import 'package:flutter/material.dart';
import 'package:wakeway/features/destinations/viewmodels/destination_view_model.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';
import 'package:wakeway/shared/ui.dart';

class OfflineMapsScreen extends StatelessWidget {
  const OfflineMapsScreen({
    super.key,
    required this.controller,
    required this.destinationViewModel,
  });

  final WakeWayViewModel controller;
  final DestinationViewModel destinationViewModel;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([controller, destinationViewModel]),
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Offline maps')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          children: [
            const PageHeading(
              'Offline trip essentials',
              subtitle: 'Trip records stay on this device. Saved destinations sync with your account.',
            ),
            const SizedBox(height: 17),
            SurfaceCard(
              color: WakeColors.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.offline_pin_rounded,
                        color: Color(0xFF8AD9B8),
                        size: 21,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'YOUR DATA',
                        style: TextStyle(
                          color: Color(0xFFB8CBDA),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    '${destinationViewModel.destinations.length} saved places · ${controller.trips.length} trip records',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'GPS monitoring and trip history work offline. Saved destinations sync with your account and load when online.',
                    style: TextStyle(
                      color: Color(0xFFB8CBDA),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Offline mode',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                subtitle: const Text(
                  'Show saved map tiles only. GPS tracking stays available.',
                  style: TextStyle(fontSize: 11),
                ),
                value: controller.offlineMode,
                onChanged: controller.setOfflineMode,
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Map tiles'),
                  const SizedBox(height: 6),
                  const Text(
                    'Tiles are saved automatically as you view the map online (up to 1 GB). Offline mode shows saved tiles only. Pan and zoom across an area while online to cache it before your trip; this does not download a whole region.',
                    style: TextStyle(
                      color: WakeColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        controller.offlineMode
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_done_rounded,
                        color: controller.offlineMode
                            ? WakeColors.muted
                            : WakeColors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.offlineMode
                              ? 'Online map requests paused'
                              : 'Map tiles load when connected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
