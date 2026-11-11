import 'package:flutter/material.dart';
import 'package:wakeway/features/trips/models/trips.dart';
import 'package:wakeway/features/trips/views/trip_history.dart';
import 'package:wakeway/shared/ui.dart';
import 'package:wakeway/features/wake/viewmodels/wakeway_view_model.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({
    super.key,
    required this.controller,
    required this.onResumeTrip,
  });

  final WakeWayViewModel controller;
  final ValueChanged<WakeTrip> onResumeTrip;

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
            const SectionLabel('Unfinished trips'),
            const SizedBox(height: 10),
            if (controller.unfinishedTrips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No trips are waiting to be resumed.'),
              ),
            for (var index = 0;
                index < controller.unfinishedTrips.length;
                index++) ...[
              _UnfinishedTripCard(
                trip: controller.unfinishedTrips[index],
                isMonitoring:
                    controller.isMonitoring &&
                    controller.activeTripId ==
                        controller.unfinishedTrips[index].id,
                anotherTripIsMonitoring:
                    controller.isMonitoring &&
                    controller.activeTripId !=
                        controller.unfinishedTrips[index].id,
                onTap: onResumeTrip,
              ),
              if (index < controller.unfinishedTrips.length - 1)
                const SizedBox(height: 9),
            ],
            const SizedBox(height: 14),
            const SectionLabel('Recent activity'),
            const SizedBox(height: 10),
            TripHistoryList(trips: controller.trips),
          ],
        ),
      ),
    ),
  );
}

class _UnfinishedTripCard extends StatelessWidget {
  const _UnfinishedTripCard({
    required this.trip,
    required this.isMonitoring,
    required this.anotherTripIsMonitoring,
    required this.onTap,
  });

  final WakeTrip trip;
  final bool isMonitoring;
  final bool anotherTripIsMonitoring;
  final ValueChanged<WakeTrip> onTap;

  @override
  Widget build(BuildContext context) {
    final startedAt = trip.startedAt.toLocal();
    final startedLabel =
        '${MaterialLocalizations.of(context).formatMediumDate(startedAt)} · '
        '${TimeOfDay.fromDateTime(startedAt).format(context)}';
    final actionLabel = isMonitoring
        ? 'Open trip'
        : anotherTripIsMonitoring
        ? 'Another trip is active'
        : 'Resume monitoring';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: anotherTripIsMonitoring ? null : () => onTap(trip),
        child: SurfaceCard(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const IconTile(
                icon: Icons.play_circle_outline_rounded,
                color: WakeColors.blue,
                background: WakeColors.blueSoft,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destinationName,
                      style: const TextStyle(
                        color: WakeColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.status == 'active' ? 'Not finished' : trip.status} · $startedLabel',
                      style: const TextStyle(
                        color: WakeColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    isMonitoring
                        ? Icons.gps_fixed_rounded
                        : Icons.play_arrow_rounded,
                    color: anotherTripIsMonitoring
                        ? WakeColors.muted
                        : WakeColors.blue,
                    size: 21,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: anotherTripIsMonitoring
                          ? WakeColors.muted
                          : WakeColors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
