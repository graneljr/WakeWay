import 'package:flutter/material.dart';
import 'package:wakeway/shared/ui.dart';
import 'package:wakeway/features/trips/models/wake_trip_record.dart';

class TripHistoryList extends StatelessWidget {
  const TripHistoryList({super.key, required this.trips});

  final List<WakeTripRecord> trips;

  String _formatDateTime(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour < 12 ? 'AM' : 'PM';
    return '${months[local.month - 1]} ${local.day} · $hour:$minute $suffix';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes.clamp(1, 59)} min';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (trips.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Text('Your completed trips will appear here.'),
        ),
      for (var index = 0; index < trips.length; index++) ...[
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Column(
                children: [
                  Icon(
                    trips[index].alarmTriggered
                        ? Icons.notifications_active_rounded
                        : Icons.circle,
                    color: trips[index].alarmTriggered
                        ? WakeColors.green
                        : WakeColors.muted,
                    size: 17,
                  ),
                  if (index < trips.length - 1)
                    Container(width: 2, height: 40, color: WakeColors.line),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trips[index].destination,
                      style: const TextStyle(
                        color: WakeColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDateTime(trips[index].startedAt)} · ${_formatDuration(trips[index].duration)}',
                      style: const TextStyle(
                        color: WakeColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    trips[index].alarmTriggered
                        ? Icons.notifications_active_rounded
                        : Icons.check_circle_rounded,
                    color: trips[index].alarmTriggered
                        ? WakeColors.green
                        : WakeColors.muted,
                    size: 17,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    trips[index].alarmTriggered ? 'Alarm rang' : 'Trip ended',
                    style: TextStyle(
                      color: trips[index].alarmTriggered
                          ? WakeColors.green
                          : WakeColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (index < trips.length - 1) const SizedBox(height: 9),
      ],
    ],
  );
}
