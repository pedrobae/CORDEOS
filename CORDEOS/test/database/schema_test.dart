// test/database/schema_test.dart
//
// Verifies that the current (latest) schema is created correctly from scratch.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/db_helpers.dart';

/// Called from test_main.dart — no setUpAll here.
void register() {
  group('Schema (v26 fresh)', () {
    late Database db;

    setUp(() async => db = await createFreshDb(26));
    tearDown(() async => db.close());

    test('All expected tables exist', () async {
      final tables = await tableNames(db);
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
        expect(tables, contains(t), reason: 'Table "$t" should exist');
      }
    });

    test('cipher columns', () async {
      final cols = await columnNames(db, 'cipher');
      expect(
        cols,
        containsAll([
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
        ]),
      );
    });

    test('version columns', () async {
      final cols = await columnNames(db, 'version');
      expect(
        cols,
        containsAll([
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
        ]),
      );
    });

    test('section columns', () async {
      final cols = await columnNames(db, 'section');
      expect(
        cols,
        containsAll([
          'id',
          'version_id',
          'key',
          'content_type',
          'content_text',
          'content_color',
        ]),
      );
    });

    test('cloud_version_note has title column', () async {
      expect(await columnNames(db, 'cloud_version_note'), contains('title'));
    });

    test('cloud_version_key_overwrite schema', () async {
      expect(
        await columnNames(db, 'cloud_version_key_overwrite'),
        containsAll(['id', 'firebase_version_id', 'key']),
      );
    });

    test('Foreign keys are enabled', () async {
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], 1);
    });
  });
}
