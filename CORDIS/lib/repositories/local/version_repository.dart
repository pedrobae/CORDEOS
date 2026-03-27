import 'package:cordis/models/domain/cipher/version.dart';

import 'package:cordis/helpers/database.dart';
import 'package:cordis/repositories/local/section_repository.dart';

class LocalVersionRepository {
  final _databaseHelper = DatabaseHelper();

  final _sectionRepo = SectionRepository();

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
      versions.add(await _buildVersion(row));
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

    Version version = await _buildVersion(result[0]);

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

    return _buildVersion(result[0]);
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

    return _buildVersion(result[0]);
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

  /// Updates specific field(s) of a version
  Future<void> updateFieldOfVersion(
    int versionId,
    Map<String, dynamic> field,
  ) async {
    final db = await _databaseHelper.database;
    await db.update('version', field, where: 'id = ?', whereArgs: [versionId]);
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

  Future<Version> _buildVersion(Map<String, dynamic> row) async {
    final section = await _sectionRepo.getSections(row['id']);
    return Version.fromSqLiteNoSections(row).copyWith(content: section);
  }
}
