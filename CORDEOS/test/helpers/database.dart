import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cordeos/helpers/database.dart' as appSqlite;

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

/// Opens a fresh in-memory DB at a given [version] by running onCreate.
Future<Database> _createFreshDb(int version) async {
  return openDatabase(
    inMemoryDatabasePath,
    version: version,
    onCreate: (db, v) => appSqlite.DatabaseHelper().testOnCreate(db, v),
  );
}

/// Simulates an upgrade path by first creating a DB at [fromVersion]
/// then re-opening it targeting [toVersion], which triggers onUpgrade.
Future<Database> _upgradeDb(int fromVersion, int toVersion) async {
  // Step 1 – create the "old" schema
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: fromVersion,
    onCreate: (db, v) => appSqlite.DatabaseHelper().testOnCreate(db, v),
  );
  await db.close();

  // Step 2 – re-open and upgrade
  return openDatabase(
    inMemoryDatabasePath,
    version: toVersion,
    onCreate: (db, v) => appSqlite.DatabaseHelper().testOnCreate(db, v),
    onUpgrade: (db, old, nw) =>
        appSqlite.DatabaseHelper().testOnUpgrade(db, old, nw),
  );
}

/// Returns the list of table names present in [db].
Future<List<String>> _tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
  );
  return rows.map((r) => r['name'] as String).toList();
}

/// Returns the column names of [table] in [db].
Future<List<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name'] as String).toList();
}

// ─────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── Fresh schema (v26) ──────────────────────────────────────────────────────
  group('Fresh database creation (v26)', () {
    late Database db;

    setUp(() async {
      db = await _createFreshDb(26);
    });

    tearDown(() async => db.close());

    test('All expected tables are created', () async {
      final tables = await _tableNames(db);
      const expected = [
        'tag',
        'cipher',
        'cipher_tags',
        'version',
        'section',
        'user',
        'playlist',
        'playlist_version',
        'user_playlist',
        'flow_item',
        'schedule',
        'role',
        'role_member',
        'cloud_version_note',
        'cloud_version_key_overwrite',
      ];
      for (final t in expected) {
        expect(
          tables,
          contains(t),
          reason: 'Table "$t" should exist after onCreate',
        );
      }
    });

    test('cipher table has required columns', () async {
      final cols = await _columnNames(db, 'cipher');
      for (final c in [
        'id',
        'title',
        'author',
        'music_key',
        'language',
        'links',
        'firebase_id',
        'is_deleted',
        'updated_at',
        'created_at',
      ]) {
        expect(cols, contains(c), reason: 'cipher.$c missing');
      }
    });

    test('version table has required columns', () async {
      final cols = await _columnNames(db, 'version');
      for (final c in [
        'id',
        'cipher_id',
        'song_structure',
        'duration',
        'bpm',
        'transposed_key',
        'version_name',
        'firebase_cipher_id',
        'firebase_id',
        'notes',
        'created_at',
      ]) {
        expect(cols, contains(c), reason: 'version.$c missing');
      }
    });

    test('section table has required columns', () async {
      final cols = await _columnNames(db, 'section');
      for (final c in [
        'id',
        'version_id',
        'key',
        'content_type',
        'content_text',
        'content_color',
      ]) {
        expect(cols, contains(c), reason: 'section.$c missing');
      }
    });

    test('cloud_version_note table has title column', () async {
      final cols = await _columnNames(db, 'cloud_version_note');
      expect(cols, contains('title'));
    });

    test(
      'cloud_version_key_overwrite table exists with correct schema',
      () async {
        final cols = await _columnNames(db, 'cloud_version_key_overwrite');
        expect(cols, containsAll(['id', 'firebase_version_id', 'key']));
      },
    );

    test('Foreign key constraints are active (PRAGMA foreign_keys)', () async {
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], 1);
    });
  });

  // ── Basic CRUD ──────────────────────────────────────────────────────────────
  group('CRUD operations on v26 schema', () {
    late Database db;

    setUp(() async {
      db = await _createFreshDb(26);
      await db.execute('PRAGMA foreign_keys = ON');
    });

    tearDown(() async => db.close());

    test('Insert and query a cipher', () async {
      final id = await db.insert('cipher', {
        'title': 'Amazing Grace',
        'language': 'eng',
      });
      final rows = await db.query('cipher', where: 'id = ?', whereArgs: [id]);
      expect(rows.first['title'], 'Amazing Grace');
    });

    test('Insert tag and link via cipher_tags', () async {
      final cipherId = await db.insert('cipher', {'title': 'Test Song'});
      final tagId = await db.insert('tag', {'title': 'Worship'});
      await db.insert('cipher_tags', {'tag_id': tagId, 'cipher_id': cipherId});

      final rows = await db.query(
        'cipher_tags',
        where: 'cipher_id = ?',
        whereArgs: [cipherId],
      );
      expect(rows.length, 1);
      expect(rows.first['tag_id'], tagId);
    });

    test(
      'Cascade delete: removing cipher removes version and section',
      () async {
        final cipherId = await db.insert('cipher', {'title': 'Cascade Test'});
        final versionId = await db.insert('version', {
          'cipher_id': cipherId,
          'song_structure': '',
        });
        await db.insert('section', {
          'version_id': versionId,
          'key': 1,
          'content_type': 'verse',
          'content_text': 'Hello world',
        });

        await db.delete('cipher', where: 'id = ?', whereArgs: [cipherId]);

        final versions = await db.query(
          'version',
          where: 'cipher_id = ?',
          whereArgs: [cipherId],
        );
        final sections = await db.query(
          'section',
          where: 'version_id = ?',
          whereArgs: [versionId],
        );
        expect(versions, isEmpty);
        expect(sections, isEmpty);
      },
    );

    test('UNIQUE constraint on cipher_tags prevents duplicates', () async {
      final cipherId = await db.insert('cipher', {'title': 'Unique Test'});
      final tagId = await db.insert('tag', {'title': 'Gospel'});
      await db.insert('cipher_tags', {'tag_id': tagId, 'cipher_id': cipherId});

      expect(
        () async =>
            db.insert('cipher_tags', {'tag_id': tagId, 'cipher_id': cipherId}),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('Insert into cloud_version_note with title', () async {
      final id = await db.insert('cloud_version_note', {
        'firebase_version_id': 'fb_v_001',
        'position': 0,
        'content': 'Some note',
        'title': 'Intro Note',
      });
      final rows = await db.query(
        'cloud_version_note',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows.first['title'], 'Intro Note');
    });

    test('UNIQUE constraint on cloud_version_key_overwrite', () async {
      await db.insert('cloud_version_key_overwrite', {
        'firebase_version_id': 'fb_v_unique',
        'key': 'C',
      });
      expect(
        () async => db.insert('cloud_version_key_overwrite', {
          'firebase_version_id': 'fb_v_unique',
          'key': 'D',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  // ── Migration tests ─────────────────────────────────────────────────────────
  group('Migration tests', () {
    test('v16 → v17 adds country, language, time_zone to user', () async {
      final db = await _upgradeDb(16, 17);
      final cols = await _columnNames(db, 'user');
      expect(cols, containsAll(['country', 'language', 'time_zone']));
      await db.close();
    });

    test('v17 → v18 drops time column from schedule', () async {
      final db = await _upgradeDb(17, 18);
      final cols = await _columnNames(db, 'schedule');
      expect(cols, isNot(contains('time')));
      await db.close();
    });

    test('v18 → v19 adds link column to cipher', () async {
      final db = await _upgradeDb(18, 19);
      final cols = await _columnNames(db, 'cipher');
      expect(cols, contains('link'));
      await db.close();
    });

    test('v20 → v21 renames link to links in cipher', () async {
      final db = await _upgradeDb(20, 21);
      final cols = await _columnNames(db, 'cipher');
      expect(cols, contains('links'));
      expect(cols, isNot(contains('link')));
      await db.close();
    });

    test('v21 → v22 adds collaborators to schedule', () async {
      final db = await _upgradeDb(21, 22);
      final cols = await _columnNames(db, 'schedule');
      expect(cols, contains('collaborators'));
      await db.close();
    });

    test('v22 → v23 adds notes to version', () async {
      final db = await _upgradeDb(22, 23);
      final cols = await _columnNames(db, 'version');
      expect(cols, contains('notes'));
      await db.close();
    });

    test('v23 → v24 creates cloud_version_note table', () async {
      final db = await _upgradeDb(23, 24);
      final tables = await _tableNames(db);
      expect(tables, contains('cloud_version_note'));
      await db.close();
    });

    test('v24 → v25 adds title column to cloud_version_note', () async {
      final db = await _upgradeDb(24, 25);
      final cols = await _columnNames(db, 'cloud_version_note');
      expect(cols, contains('title'));
      await db.close();
    });

    test('v25 → v26 creates cloud_version_key_overwrite table', () async {
      final db = await _upgradeDb(25, 26);
      final tables = await _tableNames(db);
      expect(tables, contains('cloud_version_key_overwrite'));
      await db.close();
    });

    test('Full upgrade path v16 → v26 succeeds', () async {
      final db = await _upgradeDb(16, 26);
      final tables = await _tableNames(db);
      expect(
        tables,
        containsAll([
          'cipher',
          'version',
          'section',
          'user',
          'schedule',
          'cloud_version_note',
          'cloud_version_key_overwrite',
        ]),
      );
      await db.close();
    });
  });
}
