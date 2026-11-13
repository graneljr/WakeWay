import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakeway/core/database/sqlite_helper.dart';
import 'package:wakeway/core/database/supabase_service.dart';
import 'package:wakeway/features/auth/repositories/authentication_repository.dart';

class DataSyncSummary {
  const DataSyncSummary({
    required this.destinationCount,
    required this.tripCount,
  });

  final int destinationCount;
  final int tripCount;
}

/// Merges the signed-in user's SQLite snapshot with their Supabase backup.
class DataSyncService {
  DataSyncService({
    required this.authenticationRepository,
    SupabaseClient? client,
    SQLiteHelper? database,
  }) : _client = client ?? SupabaseService.client,
       _database = database ?? SQLiteHelper.instance;

  static const _destinationsTable = 'destinations';
  static const _tripsTable = 'trips';
  static const _pageSize = 500;

  final AuthenticationRepository authenticationRepository;
  final SupabaseClient _client;
  final SQLiteHelper _database;

  Future<DataSyncSummary> syncNow() async {
    final userId = authenticationRepository.currentUserId;
    if (userId == null) {
      throw StateError('Sign in to sync your WakeWay data.');
    }

    await _applyQueuedDestinationDeletes(userId);

    final cloudDestinations = await _fetchAll(_destinationsTable, userId);
    final deletedDestinationIds = cloudDestinations
        .where((row) => row['deleted_at'] != null)
        .map((row) => row['id'] as String)
        .toSet();
    await _database.removeCloudDeletedDestinations(
      userId: userId,
      destinationIds: deletedDestinationIds,
    );

    final localDestinations = await _database.getDestinations(userId);
    final localTrips = await _database.getTrips(userId);
    final cloudTrips = await _fetchAll(_tripsTable, userId);

    final destinations = _mergeRows(
      local: localDestinations.map(_destinationForCloud).toList(),
      cloud: cloudDestinations
          .where((row) => row['deleted_at'] == null)
          .map(_destinationForCloud)
          .toList(),
    );
    final trips = _mergeRows(
      local: localTrips.map(_tripForCloud).toList(),
      cloud: cloudTrips.map(_tripForCloud).toList(),
    );
    final destinationIds = destinations.keys.toSet();
    for (final trip in trips.values) {
      final destinationId = trip['destination_id'];
      if (destinationId is String && !destinationIds.contains(destinationId)) {
        trip['destination_id'] = null;
        trip['updated_at'] = _now();
      }
    }

    // Upload destinations first because trips can reference a saved destination.
    await _upsertAll(
      _destinationsTable,
      destinations.values
          .map((row) => {...row, 'deleted_at': null})
          .toList(growable: false),
    );
    await _upsertAll(_tripsTable, trips.values.toList());

    await _database.applySyncedSnapshot(
      destinations: destinations.values
          .map((row) => {...row, 'sync_status': 'synced'})
          .toList(growable: false),
      trips: trips.values.toList(growable: false),
    );
    await _database.removeSyncItemsForRecords(
      tableName: _tripsTable,
      recordIds: trips.keys.toSet(),
    );

    return DataSyncSummary(
      destinationCount: destinations.length,
      tripCount: trips.length,
    );
  }

  Future<void> _applyQueuedDestinationDeletes(String userId) async {
    final queued = await _database.getPendingSyncItems();
    for (final item in queued) {
      if (item['table_name'] != _destinationsTable ||
          item['operation'] != 'delete') {
        continue;
      }

      final payload = item['payload'];
      if (payload is! String) continue;

      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> || decoded['user_id'] != userId) {
        continue;
      }

      final deletedAt = _now();
      await _client
          .from(_destinationsTable)
          .update({'deleted_at': deletedAt, 'updated_at': deletedAt})
          .eq('id', item['record_id'] as String)
          .eq('user_id', userId);
      await _database.removeSyncItem(item['id'] as String);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAll(
    String table,
    String userId,
  ) async {
    final rows = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
      final page = await _client
          .from(table)
          .select()
          .eq('user_id', userId)
          .order('updated_at')
          .range(offset, offset + _pageSize - 1);
      final pageRows = List<Map<String, dynamic>>.from(page);
      rows.addAll(pageRows);
      if (pageRows.length < _pageSize) return rows;
      offset += _pageSize;
    }
  }

  Future<void> _upsertAll(String table, List<Map<String, dynamic>> rows) async {
    for (var start = 0; start < rows.length; start += _pageSize) {
      final end = (start + _pageSize).clamp(0, rows.length).toInt();
      await _client
          .from(table)
          .upsert(rows.sublist(start, end), onConflict: 'id');
    }
  }

  Map<String, dynamic> _destinationForCloud(Map<String, dynamic> row) => {
    'id': row['id'],
    'user_id': row['user_id'],
    'name': row['name'],
    'address': row['address'] ?? '',
    'latitude': row['latitude'],
    'longitude': row['longitude'],
    'updated_at':
        row['updated_at'] ??
        DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String(),
  };

  Map<String, dynamic> _tripForCloud(Map<String, dynamic> row) => {
    'id': row['id'],
    'user_id': row['user_id'],
    'destination_id': row['destination_id'],
    'destination_name': row['destination_name'],
    'destination_address': row['destination_address'],
    'alarm_latitude': row['alarm_latitude'],
    'alarm_longitude': row['alarm_longitude'],
    'radius_meters': row['radius_meters'],
    'warning_distance_meters': row['warning_distance_meters'],
    'vibration_enabled': _asBool(row['vibration_enabled'], fallback: true),
    'repeat_alarm': _asBool(row['repeat_alarm'], fallback: true),
    'snooze_minutes': row['snooze_minutes'] ?? 5,
    'alarm_sound': row['alarm_sound'] ?? 'WakeWay alarm',
    // A device path cannot be restored on another phone.
    'custom_alarm_sound_path': null,
    'use_advance_point': _asBool(row['use_advance_point'], fallback: false),
    'status': row['status'] ?? 'active',
    'alarm_triggered': _asBool(row['alarm_triggered'], fallback: false),
    'started_at': row['started_at'],
    'completed_at': row['completed_at'],
    'updated_at': row['updated_at'],
  };

  Map<String, Map<String, dynamic>> _mergeRows({
    required List<Map<String, dynamic>> local,
    required List<Map<String, dynamic>> cloud,
  }) {
    final merged = <String, Map<String, dynamic>>{
      for (final row in local) row['id'] as String: row,
    };

    for (final cloudRow in cloud) {
      final id = cloudRow['id'] as String;
      final localRow = merged[id];
      if (localRow == null ||
          _updatedAt(cloudRow).isAfter(_updatedAt(localRow))) {
        merged[id] = cloudRow;
      }
    }

    return merged;
  }

  DateTime _updatedAt(Map<String, dynamic> row) {
    final value = row['updated_at'];
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? DateTime(0);
    }
    return DateTime(0);
  }

  bool _asBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return fallback;
  }

  String _now() => DateTime.now().toUtc().toIso8601String();
}
