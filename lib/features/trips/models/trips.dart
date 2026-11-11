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

  factory WakeTrip.fromLocalJson(Map<String, dynamic> json) => WakeTrip(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    destinationId: json['destination_id'] as String?,
    destinationName: json['destination_name'] as String,
    destinationAddress: json['destination_address'] as String?,
    alarmLatitude: (json['alarm_latitude'] as num).toDouble(),
    alarmLongitude: (json['alarm_longitude'] as num).toDouble(),
    radiusMeters: (json['radius_meters'] as num).toInt(),
    warningDistanceMeters: (json['warning_distance_meters'] as num).toInt(),
    vibrationEnabled: _asBool(json['vibration_enabled'], fallback: true),
    repeatAlarm: _asBool(json['repeat_alarm'], fallback: true),
    snoozeMinutes: (json['snooze_minutes'] as num?)?.toInt() ?? 5,
    alarmSound: json['alarm_sound'] as String? ?? 'WakeWay alarm',
    customAlarmSoundPath: json['custom_alarm_sound_path'] as String?,
    useAdvancePoint: _asBool(json['use_advance_point'], fallback: false),
    status: json['status'] as String? ?? 'active',
    startedAt: DateTime.parse(json['started_at'] as String),
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at'] as String),
    alarmTriggered: _asBool(json['alarm_triggered'], fallback: false),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  static bool _asBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return fallback;
  }



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
