import 'package:cordeos/models/domain/cipher/version.dart';

import 'package:cordeos/helpers/database.dart';
import 'package:cordeos/models/dtos/version_dto.dart';

class LocalVersionRepository {
  final _databaseHelper = DatabaseHelper();

  // ============= VERSION OPERATIONS =============
  // ===== CREATE =====
  /// Inserts a version to the SQLite database
  /// Returns the local ID of the inserted version
  Future<int> insertVersion(Version version) async {
    final db = await _databaseHelper.database;
    return await db.insert('version', version.toSqLite());
  }

  // ===== READ =====
  /// Gets all versions of a cipher
  Future<List<Version>> getUnloadedVersions(
    int cipherId,
    List<int> loadedIds,
  ) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'version',
      where:
          'cipher_id = ?${loadedIds.isNotEmpty ? ' AND id NOT IN (${loadedIds.join(',')})' : ''}',
      whereArgs: [cipherId],
      orderBy: 'id',
    );

    List<Version> versions = [];
    for (var row in results) {
      versions.add(Version.fromSqLite(row));
    }

    return versions;
  }

  /// Gets version by its local ID
  /// Returns null if not found
  Future<Version?> getVersionWithId(int versionId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'version',
      where: 'id = ?',
      whereArgs: [versionId],
    );

    if (result.isEmpty) return null;

    Version version = Version.fromSqLite(result[0]);

    return version;
  }

  /// Gets version by its Firebase ID
  /// Returns null if not found
  Future<Version?> getVersionWithFirebaseId(String firebaseId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'version',
      where: 'firebase_id = ?',
      whereArgs: [firebaseId],
    );

    if (result.isEmpty) return null;

    return Version.fromSqLite(result[0]);
  }

  Future<Version> getOldestVersionOfCipher(int cipherId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'version',
      where: 'cipher_id = ?',
      whereArgs: [cipherId],
      orderBy: 'created_at ASC',
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No versions found for cipher with ID $cipherId');
    }

    return Version.fromSqLite(result[0]);
  }

  // ===== UPDATE =====
  /// Updates entire version
  Future<void> updateVersion(Version version) async {
    final db = await _databaseHelper.database;
    await db.update(
      'version',
      version.toSqLite(),
      where: 'id = ?',
      whereArgs: [version.id],
    );
  }

  // ===== DELETE =====
  /// Deletes version by its local ID,
  /// if it leaves the cipher without any versions, deletes the cipher as well and returns its index
  Future<int?> deleteVersion(int id) async {
    final db = await _databaseHelper.database;
    final cipherID = await db.transaction((txn) async {
      final result = await txn.query(
        'version',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final cipherId = result.first['cipher_id'] as int?;

      await txn.delete('version', where: 'id = ?', whereArgs: [id]);

      final remainingVersion = await txn.query(
        'version',
        where: 'cipher_id = ?',
        whereArgs: [cipherId],
        limit: 1,
      );

      if (remainingVersion.isEmpty) {
        await txn.delete('cipher', where: 'id = ?', whereArgs: [cipherId]);
        return cipherId;
      }
      return null;
    });
    return cipherID;
  }

  // Cloud version notes
  // CREATE
  Future<int> createNote(CloudVersionNote note) async {
    final db = await _databaseHelper.database;
    final result = await db.insert('cloud_version_note', note.toSqlite());
    return result;
  }

  // READ
  Future<Map<int, CloudVersionNote>> getNotesOfVersion(
    String cloudVersionFirebaseID,
  ) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'cloud_version_note',
      where: 'firebase_version_id = ?',
      whereArgs: [cloudVersionFirebaseID],
    );
    final map = <int, CloudVersionNote>{};
    for (final row in result) {
      map[row['id'] as int] = CloudVersionNote.fromSqlite(row);
    }
    return map;
  }

  Future<Map<String, Map<int, CloudVersionNote>>> getNotes() async {
    final db = await _databaseHelper.database;
    final result = await db.query('cloud_version_note');

    final map = <String, Map<int, CloudVersionNote>>{};
    for (final row in result) {
      map[row['firebase_version_id'] as String] ??= {};
      map[row['firebase_version_id'] as String]![row['id'] as int] =
          CloudVersionNote.fromSqlite(row);
    }
    return map;
  }

  // UPDATE
  Future<void> updateNote(int id, CloudVersionNote note) async {
    final db = await _databaseHelper.database;
    await db.update(
      'cloud_version_note',
      note.toSqlite(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  Future<void> deleteNote(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('cloud_version_note', where: 'id = ?', whereArgs: [id]);
  }

  // ======== OVERWRITE KEY ==============

  Future<void> saveKey(String key, String firebaseVersionID) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      final result = await txn.query(
        'cloud_version_key_overwrite',
        where: 'firebase_version_id = ?',
        whereArgs: [firebaseVersionID],
        limit: 1,
      );

      if (result.isEmpty) {
        await txn.insert('cloud_version_key_overwrite', {
          'firebase_version_id': firebaseVersionID,
          'key': key,
        });
      } else {
        await txn.update(
          'cloud_version_key_overwrite',
          {'key': key},
          where: 'firebase_version_id = ?',
          whereArgs: [firebaseVersionID],
        );
      }
    });
  }

  Future<String?> loadOverwriteKeyOfVersion(String firebaseVersionID) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'cloud_version_key_overwrite',
      columns: ['key'],
      where: 'firebase_version_id = ?',
      whereArgs: [firebaseVersionID],
    );

    return result.firstOrNull?['key'] as String?;
  }

  Future<Map<String, String>> loadOverwriteKeys() async {
    final db = await _databaseHelper.database;
    final result = await db.query('cloud_version_key_overwrite');

    final map = <String, String>{};
    for (final row in result) {
      map[row['firebase_version_id'] as String] = row['key'] as String;
    }

    return map;
  }
}
