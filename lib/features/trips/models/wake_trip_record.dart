class WakeTripRecord {
  /// Creates a trip history record.
  const WakeTripRecord({
    required this.destination,
    required this.startedAt,
    required this.endedAt,
    required this.alarmTriggered,
  });

  final String destination;
  final DateTime startedAt;
  final DateTime endedAt;
  final bool alarmTriggered;

  /// Calculates the trip length from its start and end times.
  Duration get duration => endedAt.difference(startedAt);

  /// Converts the trip record to a JSON-ready map.
  Map<String, Object?> toJson() => {
    'destination': destination,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'alarmTriggered': alarmTriggered,
  };

  /// Creates a trip record from saved JSON data.
  factory WakeTripRecord.fromJson(Map<String, dynamic> json) => WakeTripRecord(
    destination: json['destination'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: DateTime.parse(json['endedAt'] as String),
    alarmTriggered: json['alarmTriggered'] as bool? ?? false,
  );
}
