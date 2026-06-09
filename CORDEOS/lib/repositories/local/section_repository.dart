import 'package:cordeos/models/domain/cipher/section.dart';

import 'package:cordeos/helpers/database.dart';

class SectionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== CREATE =====
  /// Inserts a section to the SQLite database
  /// Returns the local ID of the inserted section
  Future<int> insertSection(Section section) async {
    final db = await _databaseHelper.database;
    return await db.insert('section', section.toSqlite());
  }

  Future<int> upsertSection(Section section) async {
    final db = await _databaseHelper.database;

    final existing = await db.query(
      'section',
      where: 'version_id = ? AND key = ?',
      whereArgs: [section.versionID, section.key],
    );

    if (existing.isNotEmpty) {
      // Section exists, update it
      await db.update(
        'section',
        section.toSqlite(),
        where: 'version_id = ? AND key = ?',
        whereArgs: [section.versionID, section.key],
      );
      return existing.first['id'] as int;
    } else {
      // Section doesn't exist, insert it
      final id = await db.insert('section', section.toSqlite());
      return id;
    }
  }

  // ===== READ =====
  /// Gets all sections of a version
  Future<Map<int, Section>> getSections(int versionId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'section',
      where: 'version_id = ?',
      whereArgs: [versionId],
      orderBy: 'key',
    );

    final sections = <int, Section>{};
    for (var row in results) {
      sections[row['key'] as int] = Section.fromSqLite(row);
    }
    return sections;
  }

  Future<Section?> getSection(int versionId, int sectionKey) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'section',
      where: 'version_id = ? AND key = ?',
      whereArgs: [versionId, sectionKey],
    );

    if (results.isNotEmpty) {
      return Section.fromSqLite(results.first);
    } else {
      return null;
    }
  }

  // ===== UPDATE =====
  /// Replaces entire section
  Future<void> updateSection(Section section) async {
    final db = await _databaseHelper.database;
    await db.update(
      'section',
      section.toSqlite(),
      where: 'version_id = ? AND key = ?',
      whereArgs: [section.versionID, section.key],
    );
  }

  // ===== DELETE =====
  /// Deletes section by its versionID and sectionKey
  Future<void> deleteSection(int versionID, int sectionKey) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'section',
      where: 'version_id = ? AND key = ?',
      whereArgs: [versionID, sectionKey],
    );
  }

  Future<void> deleteSections(int versionID) async {
    final db = await _databaseHelper.database;
    await db.delete('section', where: 'version_id = ?', whereArgs: [versionID]);
  }
}
