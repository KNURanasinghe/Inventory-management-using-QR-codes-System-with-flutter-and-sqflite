import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        quantity INTEGER NOT NULL
      )
    ''');
  }

  Future<int> addItem(String name, String code, int quantity) async {
    final db = await instance.database;
    return await db.insert('inventory', {'name': name, 'code': code, 'quantity': quantity});
  }

  Future<int> updateItemQuantity(String code, int quantity) async {
    final db = await instance.database;
    return await db.update('inventory', {'quantity': quantity}, where: 'code = ?', whereArgs: [code]);
  }

  Future<int> removeItem(String code) async {
    final db = await instance.database;
    return await db.delete('inventory', where: 'code = ?', whereArgs: [code]);
  }

  Future<Map<String, dynamic>?> fetchItemByCode(String code) async {
  final db = await instance.database;
  final result = await db.query(
    'inventory',
    where: 'code = ?',
    whereArgs: [code],
    limit: 1, // Limit to 1 to fetch a single record
  );

  if (result.isNotEmpty) {
    return result.first; // Return the first matching record
  } else {
    return null; // Return null if no item found
  }
}


  Future<List<Map<String, dynamic>>> fetchAllItems() async {
    final db = await instance.database;
    return await db.query('inventory');
  }
}
