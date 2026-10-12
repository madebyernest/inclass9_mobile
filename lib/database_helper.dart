import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db"; // unchanged from Part I
  static const _databaseVersion = 2; // was 1: raised by exactly one
  static const table = 'my_table'; // Part I table: never dropped or altered
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';
  late Database _db;

  /// Lets the repository run catalogue queries on the same connection.
  Database get db => _db;

  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      // Runs before create/upgrade on every open. Without it,
      // ON DELETE CASCADE is declared but silently never enforced.
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Fresh install: build the COMPLETE version-2 schema.
  // (sqflite runs onCreate/onUpgrade inside one transaction, so a failure
  // rolls everything back. Don't nest db.transaction() in here.)
  Future _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE $table (
$columnId INTEGER PRIMARY KEY,
$columnName TEXT NOT NULL,
$columnAge INTEGER NOT NULL
)
''');
    await _createCatalogue(db);
    await _seedOnce(db);
  }

  // Existing install (v1 -> v2): add the new tables ONLY.
  // The Part I table and its rows are not touched.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCatalogue(db);
      await _seedOnce(db);
    }
  }

  Future<void> _createCatalogue(Database db) async {
    await db.execute('''
CREATE TABLE folders (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE cards (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  title     TEXT NOT NULL,
  suit      TEXT NOT NULL,
  notes     TEXT NOT NULL DEFAULT '',
  image_ref TEXT,
  folder_id INTEGER NOT NULL,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
)''');
    await db.execute('CREATE INDEX idx_cards_folder_id ON cards(folder_id)');
  }

  // Runs only from onCreate/onUpgrade, so exactly once. Never call from build().
  Future<void> _seedOnce(Database db) async {
    final folderId = await db.insert('folders', {
      'name': 'Sample Drawer',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('cards', {
      'title': 'Ace of Spades',
      'suit': 'Spades',
      'notes': '',
      'image_ref': null,
      'folder_id': folderId, // use the returned ID, never assume 1
    });
  }

  // ---------- Part I methods (unchanged) ----------
  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table);
  }

  Future<int> queryRowCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    int id = row[columnId];
    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}