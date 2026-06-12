import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'laporan_lapangan.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laporan_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT,
        deskripsi TEXT,
        foto_path TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
  }

  // دالة الإضافة
  Future<int> insertLaporan(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('laporan_table', row);
  }

  // دالة القراءة
  Future<List<Map<String, dynamic>>> getLaporanList() async {
    Database db = await database;
    return await db.query('laporan_table', orderBy: 'id DESC');
  }

  // ==========================================
  // دوال الحذف (تم إصلاح مكانها هنا)
  // ==========================================

  // دالة حذف تقرير واحد محدد
  Future<int> deleteLaporan(int id) async {
    Database db = await database;
    return await db.delete('laporan_table', where: 'id = ?', whereArgs: [id]);
  }

  // دالة مسح كل التقارير دفعة واحدة
  Future<int> deleteAllLaporan() async {
    Database db = await database;
    return await db.delete('laporan_table');
  }
}
