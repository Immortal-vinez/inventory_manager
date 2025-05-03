import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Create inventory table
        db.execute(
          'CREATE TABLE inventory(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, quantity INTEGER, price REAL, imageUrl TEXT)',
        );
        // Create sales table
        db.execute(
          'CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, quantity INTEGER, price REAL)',
        );
      },
    );
  }

  // Insert a new item
  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert(
      'inventory',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Retrieve all items
  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query('inventory');
  }

  // Update an existing item
  Future<void> updateItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.update(
      'inventory',
      item,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  // Delete an item
  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Retrieve all sales records
  Future<List<Map<String, dynamic>>> getSalesRecords() async {
    final db = await database;
    return await db.query('sales');
  }

  // Insert a new sales record
  Future<void> insertSalesRecord(Map<String, dynamic> record) async {
    final db = await database;
    await db.insert(
      'sales',
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}