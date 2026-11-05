
import 'package:flutter/material.dart';
import 'package:wakeway/features/trips/views/trip_history.dart';
import 'package:wakeway/ui.dart';
import 'package:wakeway/wakeway_controller.dart';
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key, required this.controller});

  final WakeWayController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              'Your trips',
              subtitle: 'A little peace of mind, ride after ride.',
            ),
            const SizedBox(height: 19),
            SurfaceCard(
              color: WakeColors.navy,
              child: Row(
                children: [
                  const IconTile(
                    icon: Icons.insights_rounded,
                    color: Color(0xFF9DC4FF),
                    background: Color(0xFF254562),
                    size: 48,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This month',
                          style: TextStyle(
                            color: Color(0xFFB5C7D7),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${controller.trips.length} rides monitored',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${controller.trips.where((trip) => trip.alarmTriggered).length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'safe\narrivals',
                    style: TextStyle(
                      color: Color(0xFFB5C7D7),
                      height: 1.2,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Recent activity'),
            const SizedBox(height: 10),
            TripHistoryList(trips: controller.trips),
          ],
        ),
      ),
    ),
  );
}
