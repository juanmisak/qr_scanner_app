import 'package:path/path.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart'
    as domain; // Alias para evitar colisión
import 'package:sqflite/sqflite.dart';

abstract class ScanHistoryLocalDataSource {
  Future<void> initDb();
  Future<int> addScan(domain.ScanResult scan);
  Future<List<domain.ScanResult>> getScans();
}

const String _dbName = 'scan_history.db';
const String _tableName = 'scan_history';
const String _colId = 'id';
const String _colContent = 'content';
const String _colTimestamp = 'timestamp';

class ScanHistoryLocalDataSourceImpl implements ScanHistoryLocalDataSource {
  Database? _db;

  // Abre (o crea) la base de datos
  @override
  Future<void> initDb() async {
    if (_db != null) return; // Ya inicializado
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_tableName (
              $_colId INTEGER PRIMARY KEY AUTOINCREMENT,
              $_colContent TEXT NOT NULL,
              $_colTimestamp INTEGER NOT NULL
            )
          ''');
        },
      );
      print("Database initialized at $path");
    } catch (e) {
      print("Error initializing database: $e");
      rethrow; // Propaga el error para que el repositorio lo maneje
    }
  }

  Future<Database> _getDb() async {
    await initDb(); // Asegura que esté inicializado
    if (_db == null) throw Exception("Database not initialized");
    return _db!;
  }

  @override
  Future<int> addScan(domain.ScanResult scan) async {
    try {
      final db = await _getDb();
      // Convierte la entidad del dominio a un Map para la DB
      final map = {
        _colContent: scan.content,
        _colTimestamp: scan.timestamp.millisecondsSinceEpoch,
      };
      return await db.insert(
        _tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error adding scan: $e");
      throw Exception("Failed to add scan to local database");
    }
  }

  @override
  Future<List<domain.ScanResult>> getScans() async {
    try {
      final db = await _getDb();
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: '$_colTimestamp DESC', // Muestra los más recientes primero
      );

      return List.generate(maps.length, (i) {
        return domain.ScanResult(
          id: maps[i][_colId] as int?, // El ID puede ser null antes de guardar
          content: maps[i][_colContent] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            maps[i][_colTimestamp] as int,
          ),
        );
      });
    } catch (e) {
      print("Error getting scans: $e");
      throw Exception("Failed to retrieve scans from local database");
    }
  }
}
