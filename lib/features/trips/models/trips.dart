class WakeTrip {
  const WakeTrip({
    required this.id,
    required this.userId,
    this.destinationId,
    required this.destinationName,
    this.destinationAddress,
    required this.alarmLatitude,
    required this.alarmLongitude,
    required this.radiusMeters,
    required this.warningDistanceMeters,
    required this.vibrationEnabled,
    required this.repeatAlarm,
    required this.snoozeMinutes,
    required this.alarmSound,
    required this.customAlarmSoundPath,
    required this.useAdvancePoint,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.alarmTriggered,
    required this.updatedAt,
  });

  final String id;
  final String userId;

  // Optional saved destination relationship.
  final String? destinationId;

  // Location snapshot.
  final String destinationName;
  final String? destinationAddress;
  final double alarmLatitude;
  final double alarmLongitude;

  // Trip configuration.
  final int radiusMeters;
  final int warningDistanceMeters;
  final bool vibrationEnabled;
  final bool repeatAlarm;
  final int snoozeMinutes;
  final String alarmSound;
  final String? customAlarmSoundPath;
  final bool useAdvancePoint;

  // Trip state.
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool alarmTriggered;
  final DateTime updatedAt;



  Map<String, dynamic> toLocalJson() {
  return {
    'id': id,
    'user_id': userId,
    'destination_id': destinationId,
    'destination_name': destinationName,
    'destination_address': destinationAddress,
    'alarm_latitude': alarmLatitude,
    'alarm_longitude': alarmLongitude,
    'radius_meters': radiusMeters,
    'warning_distance_meters': warningDistanceMeters,
    'vibration_enabled': vibrationEnabled,
    'repeat_alarm': repeatAlarm,
    'snooze_minutes': snoozeMinutes,
    'alarm_sound': alarmSound,
    'custom_alarm_sound_path': customAlarmSoundPath,
    'use_advance_point': useAdvancePoint ? 1 : 0,
    'status': status,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'alarm_triggered': alarmTriggered ? 1 : 0,
    'updated_at': updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> toCloudJson() {
  return {
    'id': id,
    'user_id': userId,
    'destination_id': destinationId,
    'destination_name': destinationName,
    'destination_address': destinationAddress,
    'alarm_latitude': alarmLatitude,
    'alarm_longitude': alarmLongitude,
    'radius_meters': radiusMeters,
    'warning_distance_meters': warningDistanceMeters,
    'vibration_enabled': vibrationEnabled,
    'repeat_alarm': repeatAlarm,
    'snooze_minutes': snoozeMinutes,
    'alarm_sound': alarmSound,
    'custom_alarm_sound_path': customAlarmSoundPath,
    'use_advance_point': useAdvancePoint,
    'status': status,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'alarm_triggered': alarmTriggered,
    'updated_at': updatedAt.toIso8601String(),
  };
}
}
