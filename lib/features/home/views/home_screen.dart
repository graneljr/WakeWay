import 'package:flutter/material.dart';
import 'package:wakeway/features/destinations/viewmodels/destination_view_model.dart';
import 'package:wakeway/shared/painters/hero_road_painter.dart';
import 'package:wakeway/shared/ui.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.destinationViewModel,
    required this.onStartTrip,
    required this.onSetDestination,
    required this.onSaved,
    required this.onOfflineMaps,
    required this.onHistory,
    required this.onGpsStatus,
  });

  final WakeWayViewModel controller;
  final DestinationViewModel destinationViewModel;
  final VoidCallback onStartTrip;
  final VoidCallback onSetDestination;
  final VoidCallback onSaved;
  final VoidCallback onOfflineMaps;
  final VoidCallback onHistory;
  final VoidCallback onGpsStatus;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WakeWay',
                      style: TextStyle(
                        color: WakeColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'Good evening, Arman',
                      style: TextStyle(color: WakeColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You’re all caught up.')),
                ),
                icon: const Icon(Icons.notifications_none_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: WakeColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WakeColors.navy,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -2,
                  top: -8,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 76,
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                Positioned(
                  right: -20,
                  bottom: -30,
                  child: SizedBox(
                    width: 165,
                    height: 100,
                    child: CustomPaint(painter: HeroRoadPainter()),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'YOUR NEXT RIDE',
                        style: TextStyle(
                          color: Color(0xFFBCD1E2),
                          letterSpacing: 1.1,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Rest easy.\nWe’ll watch your stop.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set an alarm point and enjoy the ride.',
                      style: TextStyle(color: Color(0xFFC0D0DE), fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 190,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: onStartTrip,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Start a trip'),
                        style: FilledButton.styleFrom(
                          backgroundColor: WakeColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.gps_fixed_rounded,
                  color: controller.locationReady
                      ? WakeColors.green
                      : WakeColors.red,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.locationReady
                            ? 'GPS is ready'
                            : 'GPS needs attention',
                        style: TextStyle(
                          color: WakeColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        controller.currentPosition == null
                            ? 'Location ${controller.locationPermissionStatus}'
                            : '± ${controller.currentPosition!.accuracy.round()} m · Updated just now',
                        style: const TextStyle(
                          color: WakeColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onGpsStatus, child: const Text('Status')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionLabel(
            'Your usual stop',
            trailing: 'Change',
            onTrailing: onSetDestination,
          ),
          const SizedBox(height: 9),
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const IconTile(
                  icon: Icons.work_rounded,
                  color: WakeColors.blue,
                  background: WakeColors.blueSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destinationViewModel.defaultDestination?.name ??
                            'Add a stop',
                        style: TextStyle(
                          color: WakeColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        destinationViewModel.defaultDestination?.address ??
                            'Choose a destination to get started',
                        style: TextStyle(color: WakeColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onStartTrip,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: WakeColors.blue,
                  ),
                  tooltip: 'Set alarm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          const SectionLabel('Shortcuts'),
          const SizedBox(height: 10),
          SizedBox(
            height: 252,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: QuickAction(
                          icon: Icons.bookmark_outline_rounded,
                          title: 'Saved places',
                          subtitle: 'Your destinations',
                          color: WakeColors.blue,
                          onTap: onSaved,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: QuickAction(
                          icon: Icons.map_outlined,
                          title: 'Offline maps',
                          subtitle: 'GPS and saved places',
                          color: WakeColors.blue,
                          onTap: onOfflineMaps,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: QuickAction(
                          icon: Icons.history_rounded,
                          title: 'Trip history',
                          subtitle: 'Past commutes',
                          color: const Color(0xFF8B68C8),
                          onTap: onHistory,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: QuickAction(
                          icon: Icons.gps_fixed_rounded,
                          title: 'GPS status',
                          subtitle: 'Check your signal',
                          color: WakeColors.green,
                          onTap: onGpsStatus,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          SectionLabel(
            'Recent trip',
            trailing: 'See all',
            onTrailing: onHistory,
          ),
          const SizedBox(height: 9),
          SurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                IconTile(
                  icon: controller.trips.isEmpty
                      ? Icons.route_outlined
                      : Icons.check_rounded,
                  color: controller.trips.isEmpty
                      ? WakeColors.blue
                      : WakeColors.green,
                  background: controller.trips.isEmpty
                      ? WakeColors.blueSoft
                      : WakeColors.greenSoft,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.trips.isEmpty
                            ? 'No trips yet'
                            : controller.trips.first.destination,
                        style: TextStyle(
                          color: WakeColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        controller.trips.isEmpty
                            ? 'Completed trips appear here'
                            : '${controller.trips.first.startedAt.toLocal()} · ${controller.trips.first.duration.inMinutes} min',
                        style: const TextStyle(
                          color: WakeColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  controller.trips.isEmpty
                      ? 'Start a trip'
                      : controller.trips.first.alarmTriggered
                      ? 'Alarm rang'
                      : 'Trip ended',
                  style: TextStyle(
                    color:
                        controller.trips.isNotEmpty &&
                            controller.trips.first.alarmTriggered
                        ? WakeColors.green
                        : WakeColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
