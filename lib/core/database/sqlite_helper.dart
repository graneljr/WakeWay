import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';

class SQLiteHelper {
  static final SQLiteHelper instance = SQLiteHelper._init();

  static Database? _database;

  SQLiteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('wakeway');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
   CREATE TABLE destinations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    address TEXT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',
    updated_at TEXT
);
    ''');
    await db.execute('''
  CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        destination_id TEXT,

        destination_name TEXT NOT NULL,
        destination_address TEXT,

        alarm_latitude REAL NOT NULL,
        alarm_longitude REAL NOT NULL,

        radius_meters INTEGER NOT NULL,
        warning_distance_meters INTEGER NOT NULL,

        vibration_enabled INTEGER NOT NULL DEFAULT 1,
        repeat_alarm INTEGER NOT NULL DEFAULT 1,
        snooze_minutes INTEGER NOT NULL DEFAULT 5,

        alarm_sound TEXT NOT NULL,
        custom_alarm_sound_path TEXT,
        use_advance_point INTEGER NOT NULL DEFAULT 0,

        status TEXT NOT NULL DEFAULT 'active',
        alarm_triggered INTEGER NOT NULL DEFAULT 0,

        started_at TEXT NOT NULL,
        completed_at TEXT,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (destination_id)
          REFERENCES destinations(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_trips_user_id
      ON trips(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_trips_status
      ON trips(status)
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_created_at
      ON sync_queue(created_at)
    ''');
  }

  // INSERT
  Future<int> insertDestinations(Map<String, dynamic> destinations) async {
    final db = await instance.database;
    final row = Map<String, Object?>.from(destinations);

    return db.transaction((txn) async {
      final inserted = await txn.insert(
        'destinations',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (inserted != 0) return inserted;

      return txn.update(
        'destinations',
        row,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    });
  }

  Future<void> markDestinationSynced(String id, String userId) async {
    final db = await database;
    await db.update(
      'destinations',
      {'sync_status': 'synced'},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> removeCloudDeletedDestinations({
    required String userId,
    required Set<String> destinationIds,
  }) async {
    if (destinationIds.isEmpty) return;
    final db = await database;

    await db.transaction((txn) async {
      for (final id in destinationIds) {
        final now = DateTime.now().toUtc().toIso8601String();
        await txn.update(
          'trips',
          {'destination_id': null, 'updated_at': now},
          where: 'destination_id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );
        await txn.delete(
          'destinations',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getDestinations(String userId) async {
    final db = await instance.database;

    return await db.query(
      'destinations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getDestinationsById(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'destinations',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // UPDATE
  Future<int> updateDestination(
    String id,
    String name,
    String userId, {
    required String updatedAt,
  }) async {
    final db = await instance.database;

    return await db.update(
      'destinations',
      {'name': name.trim(), 'updated_at': updatedAt, 'sync_status': 'pending'},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  //
  Future<int> deleteDestination(
    WakeDestination destination,
    String userId,
  ) async {
    final db = await instance.database;

    return db.transaction((txn) async {
      final deleted = await txn.delete(
        'destinations',
        where: 'id = ? AND user_id = ?',
        whereArgs: [destination.id, userId],
      );
      if (deleted == 0) return 0;

      final now = DateTime.now().toUtc().toIso8601String();
      await txn.update(
        'trips',
        {'destination_id': null, 'updated_at': now},
        where: 'destination_id = ? AND user_id = ?',
        whereArgs: [destination.id, userId],
      );
      await txn.insert('sync_queue', {
        'id':
            'destination-delete-${destination.id}-${DateTime.now().microsecondsSinceEpoch}',
        'table_name': 'destinations',
        'record_id': destination.id,
        'operation': 'delete',
        'payload': jsonEncode({'user_id': userId}),
        'created_at': now,
      });
      return deleted;
    });
  }

  Future<void> applySyncedSnapshot({
    required List<Map<String, dynamic>> destinations,
    required List<Map<String, dynamic>> trips,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      for (final destination in destinations) {
        await _upsertRow(
          txn,
          'destinations',
          Map<String, Object?>.from(destination),
        );
      }

      for (final trip in trips) {
        final localTrip = Map<String, Object?>.from(trip);
        for (final key in const [
          'vibration_enabled',
          'repeat_alarm',
          'use_advance_point',
          'alarm_triggered',
        ]) {
          localTrip[key] = _toSqliteBool(localTrip[key]);
        }

        final existing = await txn.query(
          'trips',
          columns: const ['custom_alarm_sound_path'],
          where: 'id = ?',
          whereArgs: [localTrip['id']],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          localTrip['custom_alarm_sound_path'] =
              existing.first['custom_alarm_sound_path'];
        } else {
          // File paths are device-local and cannot be restored on another phone.
          localTrip['custom_alarm_sound_path'] = null;
        }

        await _upsertRow(txn, 'trips', localTrip);
      }
    });
  }

  Future<void> removeSyncItemsForRecords({
    required String tableName,
    required Set<String> recordIds,
  }) async {
    if (recordIds.isEmpty) return;
    final db = await database;
    final pending = await db.query(
      'sync_queue',
      columns: const ['id', 'record_id'],
      where: 'table_name = ?',
      whereArgs: [tableName],
    );

    final idsToRemove = pending
        .where((row) => recordIds.contains(row['record_id'] as String))
        .map((row) => row['id'] as String)
        .toList(growable: false);
    for (final id in idsToRemove) {
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> _upsertRow(
    Transaction txn,
    String table,
    Map<String, Object?> row,
  ) async {
    final inserted = await txn.insert(
      table,
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (inserted == 0) {
      await txn.update(table, row, where: 'id = ?', whereArgs: [row['id']]);
    }
  }

  int _toSqliteBool(Object? value) {
    if (value == true || value == 1 || value == '1' || value == 'true') {
      return 1;
    }
    return 0;
  }

  Future<void> insertTrip({
    required Map<String, dynamic> trip,
    required Map<String, dynamic> cloudPayload,
    required String queueId,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert(
        'trips',
        trip,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await txn.insert('sync_queue', {
        'id': queueId,
        'table_name': 'trips',
        'record_id': trip['id'],
        'operation': 'upsert',
        'payload': jsonEncode(cloudPayload),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  Future<List<Map<String, dynamic>>> getTrips(String userId) async {
    final db = await database;

    return db.query(
      'trips',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getActiveTrip(String userId) async {
    final db = await database;

    final results = await db.query(
      'trips',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'started_at DESC',
      limit: 1,
    );

    return results.isEmpty ? null : results.first;
  }

  Future<List<Map<String, dynamic>>> getUnfinishedTrips(String userId) async {
    final db = await database;

    return db.query(
      'trips',
      where: 'user_id = ? AND status != ? AND completed_at IS NULL',
      whereArgs: [userId, 'completed'],
      orderBy: 'started_at DESC',
    );
  }

  Future<void> markTripActive({
    required String tripId,
    required String userId,
    required String updatedAt,
    required Map<String, dynamic> cloudPayload,
    required String queueId,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      final updatedRows = await txn.update(
        'trips',
        {'status': 'active', 'updated_at': updatedAt},
        where: 'id = ? AND user_id = ? AND completed_at IS NULL',
        whereArgs: [tripId, userId],
      );

      if (updatedRows == 0) {
        throw StateError('This trip is no longer available to resume.');
      }

      await txn.insert('sync_queue', {
        'id': queueId,
        'table_name': 'trips',
        'record_id': tripId,
        'operation': 'upsert',
        'payload': jsonEncode(cloudPayload),
        'created_at': updatedAt,
      });
    });
  }

  Future<void> completeTrip({
    required String tripId,
    required Map<String, dynamic> cloudPayload,
    required String queueId,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'trips',
        {
          'status': 'completed',
          'completed_at': now,
          'updated_at': now,
          'alarm_triggered': cloudPayload['alarm_triggered'] == true ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [tripId],
      );

      await txn.insert('sync_queue', {
        'id': queueId,
        'table_name': 'trips',
        'record_id': tripId,
        'operation': 'upsert',
        'payload': jsonEncode(cloudPayload),
        'created_at': now,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;

    return db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeSyncItem(String id) async {
    final db = await database;

    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementSyncAttempts(String id) async {
    final db = await database;

    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
