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
    destination_id TEXT NOT NULL,

    alarm_latitude REAL NOT NULL,
    alarm_longitude REAL NOT NULL,

    radius_meters REAL NOT NULL,
    warning_distance_meters REAL NOT NULL,

    vibration_enabled INTEGER NOT NULL DEFAULT 1,
    repeat_alarm INTEGER NOT NULL DEFAULT 0,
    snooze_minutes INTEGER NOT NULL DEFAULT 5,

    alarm_sound TEXT,
    custom_alarm_sound_path TEXT,

    started_at TEXT NOT NULL,
    completed_at TEXT,

    is_done INTEGER NOT NULL DEFAULT 0,
    sync_status TEXT NOT NULL DEFAULT 'pending',

    FOREIGN KEY (destination_id)
        REFERENCES destinations(id)
);
    ''');
  }

  // INSERT
  Future<int> insertDestinations(Map<String, dynamic> destinations) async {
    final db = await instance.database;

    return await db.insert(
      'destinations',
      Map<String, Object?>.from(destinations),
    );
  }

  Future<List<Map<String, dynamic>>> getDestinations() async {
    final db = await instance.database;

    return await db.query('destinations');
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
  Future<int> updateDestination(String id, String name) async {
    final db = await instance.database;

    return await db.update(
      'destinations',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //
  Future<int> deleteDestination(WakeDestination destination) async {
    final db = await instance.database;

    return await db.delete(
      'destinations',
      where: 'id = ?',
      whereArgs: [destination.id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
