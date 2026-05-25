// test/database/crud_test.dart
//
// Basic CRUD + constraint verification against the live v26 schema.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/db_helpers.dart';

void register() {
  group('CRUD (v26)', () {
    late Database db;

    setUp(() async {
      db = await createFreshDb(26);
      await db.execute('PRAGMA foreign_keys = ON');
    });
    tearDown(() async => db.close());

    // ── cipher ──────────────────────────────────────────────────────────────
    test('Insert and query a cipher', () async {
      final id = await db.insert('cipher', {
        'title': 'Amazing Grace',
        'language': 'eng',
      });
      final rows = await db.query('cipher', where: 'id = ?', whereArgs: [id]);
      expect(rows.first['title'], 'Amazing Grace');
    });

    // ── tags ─────────────────────────────────────────────────────────────────
    test('Link tag to cipher via cipher_tags', () async {
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

    test('UNIQUE constraint on cipher_tags prevents duplicates', () async {
      final cipherId = await db.insert('cipher', {'title': 'Unique Test'});
      final tagId = await db.insert('tag', {'title': 'Gospel'});
      await db.insert('cipher_tags', {'tag_id': tagId, 'cipher_id': cipherId});

      expect(
        () =>
            db.insert('cipher_tags', {'tag_id': tagId, 'cipher_id': cipherId}),
        throwsA(isA<DatabaseException>()),
      );
    });

    // ── cascade delete ────────────────────────────────────────────────────────
    test('Cascade delete: cipher → version → section', () async {
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

      expect(
        await db.query(
          'version',
          where: 'cipher_id = ?',
          whereArgs: [cipherId],
        ),
        isEmpty,
      );
      expect(
        await db.query(
          'section',
          where: 'version_id = ?',
          whereArgs: [versionId],
        ),
        isEmpty,
      );
    });

    // ── cloud tables ──────────────────────────────────────────────────────────
    test('Insert cloud_version_note with title', () async {
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
        () => db.insert('cloud_version_key_overwrite', {
          'firebase_version_id': 'fb_v_unique',
          'key': 'D',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
