import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE inventory(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            name TEXT,
            brand TEXT,
            color TEXT,
            quantity INTEGER,
            price REAL,
            imageUrl TEXT
          )''');
        await db.execute('''
          CREATE TABLE sales(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            quantity INTEGER,
            price REAL,
            timestamp TEXT
          )''');
      },
    );
  }

  // Inventory CRUD
  Future<int> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert(
      'inventory',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query('inventory');
  }

  Future<int> updateItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    return await db.update('inventory', item, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  // Sales CRUD
  Future<int> insertSalesRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert(
      'sales',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSalesRecords() async {
    final db = await database;
    return await db.query('sales');
  }

  Future<int> updateSalesRecord(int id, Map<String, dynamic> record) async {
    final db = await database;
    return await db.update('sales', record, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSalesRecord(int id) async {
    final db = await database;
    return await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }
}
