import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'folder.dart';
import 'playing_card.dart';

/// The ONLY place SQL lives. Every value is bound with ?/whereArgs.
class CatalogueRepository {
  CatalogueRepository(this.helper);
  final DatabaseHelper helper;
  Future<Database> get _db async => helper.db;

  Future<List<Folder>> getFoldersWithCounts() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT f.id, f.name, f.created_at, COUNT(c.id) AS card_count
      FROM folders f LEFT JOIN cards c ON c.folder_id = f.id
      GROUP BY f.id
      ORDER BY f.name COLLATE NOCASE ASC''');
    return rows.map(Folder.fromMap).toList();
  }

  /// Returns the new row ID. Throws DatabaseException on duplicate name.
  Future<int> insertFolder(String name) async {
    final db = await _db;
    return db.insert('folders',
        Folder(name: name, createdAt: DateTime.now().toIso8601String()).toMap());
  }

  /// Returns rows deleted (0 means nothing matched: treat as a real result).
  /// Child cards go with it via ON DELETE CASCADE.
  Future<int> deleteFolder(int id) async {
    final db = await _db;
    return db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PlayingCard>> getCards(int folderId) async {
    final db = await _db;
    final rows = await db.query('cards',
        where: 'folder_id = ?',
        whereArgs: [folderId],
        orderBy: 'title COLLATE NOCASE ASC');
    return rows.map(PlayingCard.fromMap).toList();
  }

  Future<int> insertCard(PlayingCard c) async {
    final db = await _db;
    return db.insert('cards', c.toMap()..remove('id'));
  }

  /// Returns rows affected; 0 means the ID no longer exists.
  Future<int> updateCard(PlayingCard c) async {
    final db = await _db;
    return db.update('cards', c.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCard(int id) async {
    final db = await _db;
    return db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Read-only helper handy for T1/T4 evidence logging.
  /// [table] must be a constant you pass in, never user input.
  Future<int> countRows(String table) async {
    final db = await _db;
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM $table');
    return Sqflite.firstIntValue(r) ?? 0;
  }
}