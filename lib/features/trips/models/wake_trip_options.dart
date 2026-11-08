class WakeTripOptions {
  /// Holds the alarm and trip options selected before a trip.
  const WakeTripOptions({
    required this.radiusMeters,
    required this.warningDistanceMeters,
    required this.vibration,
    required this.repeatAlarm,
    required this.snoozeMinutes,
    required this.alarmSound,
    this.alarmSoundPath,
    required this.useAdvancePoint,
    this.advanceLatitude,
    this.advanceLongitude,
  });

  final int radiusMeters;
  final int warningDistanceMeters;
  final bool vibration;
  final bool repeatAlarm;
  final int snoozeMinutes;
  final String alarmSound;
  final String? alarmSoundPath;
  final bool useAdvancePoint;
  final double? advanceLatitude;
  final double? advanceLongitude;
}
