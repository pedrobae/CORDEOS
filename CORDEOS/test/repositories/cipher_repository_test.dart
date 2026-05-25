// test/repositories/cipher_repository_test.dart
//
// Tests for CipherRepository against a real in-memory SQLite database.
// No mocks needed for the db layer — use createFreshDb() from db_helpers.
//
// TEMPLATE: copy, rename, fill in.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/db_helpers.dart';
import 'package:cordeos/repositories/local/cipher_repository.dart';

// TODO: repository tests

void register() {
  group('CipherRepository', () {
    late Database db;
    late CipherRepository repo;

    setUp(() async {
      db = await createFreshDb(26);
      await db.execute('PRAGMA foreign_keys = ON');
    });
    tearDown(() async => db.close());

    test('getAll returns empty list on fresh db', () async {
      // expect(await repo.getAll(), isEmpty);
    });

    test('insert then getById returns the cipher', () async {
      // final id = await repo.insert(Cipher(title: 'Test'));
      // final cipher = await repo.getById(id);
      // expect(cipher?.title, 'Test');
    });

    test('update persists changes', () async {
      // final id = await repo.insert(Cipher(title: 'Before'));
      // await repo.update(Cipher(id: id, title: 'After'));
      // expect((await repo.getById(id))?.title, 'After');
    });

    test('delete removes the record', () async {
      // final id = await repo.insert(Cipher(title: 'Delete me'));
      // await repo.delete(id);
      // expect(await repo.getById(id), isNull);
    });
  });
}
