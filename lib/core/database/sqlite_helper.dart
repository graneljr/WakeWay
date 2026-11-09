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
  }

  // INSERT
  Future<int> insertDestinations(Map<String, dynamic> destinations) async {
    final db = await instance.database;

    return await db.insert('destinations', Map<String, Object?>.from(destinations));
  }

  // READ ALL
  Future<List<Map<String, dynamic>>> getDestinations() async {
    final db = await instance.database;

    return await db.query('destinations', orderBy: 'id DESC');
  }

  // READ ONE
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

  // DELETE
  Future<int> deleteDestination(WakeDestination destination) async {
    final db = await instance.database;

    return await db.delete('destinations', where: 'id = ?', whereArgs: [destination.id]);
  }

  // CLOSE DATABASE
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
