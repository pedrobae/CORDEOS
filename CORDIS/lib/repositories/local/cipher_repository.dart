import 'package:cordis/repositories/local/version_repository.dart';
import 'package:sqflite/sqflite.dart';

import 'package:cordis/models/domain/cipher/cipher.dart';

import 'package:cordis/helpers/database.dart';


class CipherRepository {
  final _databaseHelper = DatabaseHelper();

  final _versionRepo = LocalVersionRepository();

  // ===== CREATE =====
  /// Insert a pruned cipher (without versions, with tags)
  Future<int> insertPrunedCipher(Cipher cipher) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // Insert the cipher
      final cipherId = await txn.insert('cipher', cipher.toSqLite(isNew: true));

      // Insert tags if any
      if (cipher.tags.isNotEmpty) {
        for (final tagTitle in cipher.tags) {
          await _addTagInTransaction(txn, cipherId, tagTitle);
        }
      }
      return cipherId;
    });
  }

  // ===== READ =====
  /// Retrieves all ciphers without versions and sections
  /// With tags
  /// Used for lazy loading versions
  Future<List<Cipher>> getAllCiphersPruned() async {
    final db = await _databaseHelper.database;
    final results = await db.query('cipher', where: 'is_deleted = 0');

    return Future.wait(results.map((row) => _buildPrunedCipher(row)));
  }

  /// Retrieves a full cipher by its local ID
  Future<Cipher?> getCipherById(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'cipher',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    return _buildFullCipher(results.first);
  }

  /// Gets cipherId by its title and author
  /// Returns null if not found
  Future<int?> getCipherIdByTitleAuthor({
    required String title,
    required String author,
  }) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'cipher',
      where: 'title = ? AND author = ? AND is_deleted = 0',
      whereArgs: [title, author],
    );

    if (results.isEmpty) return null;

    return results.first['id'] as int;
  }

  // ===== UPDATE =====
  /// Update cipher metadata and tags
  /// Overwrites existing tags
  Future<void> updateCipher(Cipher cipher) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Update the cipher
      await txn.update(
        'cipher',
        cipher.toSqLite(),
        where: 'id = ?',
        whereArgs: [cipher.id],
      );

      // Clear existing tags
      await txn.delete(
        'cipher_tags',
        where: 'cipher_id = ?',
        whereArgs: [cipher.id],
      );

      // Insert new tags
      if (cipher.tags.isNotEmpty) {
        for (final tagTitle in cipher.tags) {
          await _addTagInTransaction(txn, cipher.id, tagTitle);
        }
      }
    });
  }

  // ===== DELETE =====
  /// Deletes cipher
  Future<void> deleteCipher(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('cipher', where: 'id = ?', whereArgs: [id]);
  }
  // ============= TAG OPERATIONS =============

  // ===== CREATE =====

  // ===== READ =====
  /// Gets all tags associated with a cipher
  Future<List<String>> getCipherTags(int cipherId) async {
    final db = await _databaseHelper.database;
    final results = await db.rawQuery(
      '''
      SELECT t.title 
      FROM tag t
      JOIN cipher_tags ct ON t.id = ct.tag_id
      WHERE ct.cipher_id = ?
    ''',
      [cipherId],
    );

    return results.map((row) => row['title'] as String).toList();
  }

  /// Gets all tags in the database
  Future<List<String>> getAllTags() async {
    final db = await _databaseHelper.database;
    final results = await db.query('tag', orderBy: 'title');
    return results.map((row) => row['title'] as String).toList();
  }

  // ===== UPDATE =====
  /// Adds a tag to a cipher
  Future<void> addTagToCipher(int cipherId, String tagTitle) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Get or create tag
      var tags = await txn.query(
        'tag',
        where: 'title = ?',
        whereArgs: [tagTitle],
      );

      int tagId;
      if (tags.isEmpty) {
        tagId = await txn.insert('tag', {'title': tagTitle});
      } else {
        tagId = tags.first['id'] as int;
      }

      // Link to cipher (ignore if already exists)
      await txn.insert('cipher_tags', {
        'tag_id': tagId,
        'cipher_id': cipherId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
  }

  // ===== DELETE =====
  /// Removes a tag from a cipher
  Future<void> removeTagFromCipher(int cipherId, String tagTitle) async {
    final db = await _databaseHelper.database;

    await db.rawDelete(
      '''
      DELETE FROM cipher_tags 
      WHERE cipher_id = ? AND tag_id = (
        SELECT id FROM tag WHERE title = ?
      )
    ''',
      [cipherId, tagTitle],
    );
  }

  // ============= PRIVATE HELPERS =============
  Future<Cipher> _buildFullCipher(Map<String, dynamic> row) async {
    final version = await _versionRepo.getUnloadedVersions(row['id'], []);
    final tags = await getCipherTags(row['id']);

    return Cipher.fromSqLite(row).copyWith(versions: version, tags: tags);
  }

  Future<Cipher> _buildPrunedCipher(Map<String, dynamic> row) async {
    final tags = await getCipherTags(row['id']);
    return Cipher.fromSqLite(row).copyWith(tags: tags);
  }

  // Helper method to add tags within a transaction
  Future<void> _addTagInTransaction(
    Transaction txn,
    int cipherId,
    String tagTitle,
  ) async {
    // Get or create tag
    var tags = await txn.query(
      'tag',
      where: 'title = ?',
      whereArgs: [tagTitle],
    );

    int tagId;
    if (tags.isEmpty) {
      tagId = await txn.insert('tag', {'title': tagTitle});
    } else {
      tagId = tags.first['id'] as int;
    }

    // Link to cipher (ignore if already exists)
    await txn.insert('cipher_tags', {
      'tag_id': tagId,
      'cipher_id': cipherId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
