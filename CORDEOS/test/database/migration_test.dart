// test/database/migration_test.dart
//
// Each test simulates upgrading from one version to the next,
// verifying that the schema change was applied correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/db_helpers.dart';

void register() {
  group('Migrations', () {
    // Helper: run a single-step upgrade and hand the db to [verify], then close.
    Future<void> checkUpgrade(
      int from,
      int to,
      Future<void> Function(Database db) verify,
    ) async {
      final db = await upgradeDb(from, to);
      await verify(db);
      await db.close();
    }

    test('v16 → v17  adds country, language, time_zone to user', () async {
      await checkUpgrade(16, 17, (db) async {
        expect(
          await columnNames(db, 'user'),
          containsAll(['country', 'language', 'time_zone']),
        );
      });
    });

    test('v17 → v18  drops time column from schedule', () async {
      await checkUpgrade(17, 18, (db) async {
        expect(await columnNames(db, 'schedule'), isNot(contains('time')));
      });
    });

    test('v18 → v19  adds link column to cipher', () async {
      await checkUpgrade(18, 19, (db) async {
        expect(await columnNames(db, 'cipher'), contains('link'));
      });
    });

    test('v20 → v21  renames link → links in cipher', () async {
      await checkUpgrade(20, 21, (db) async {
        final cols = await columnNames(db, 'cipher');
        expect(cols, contains('links'));
        expect(cols, isNot(contains('link')));
      });
    });

    test('v21 → v22  adds collaborators to schedule', () async {
      await checkUpgrade(21, 22, (db) async {
        expect(await columnNames(db, 'schedule'), contains('collaborators'));
      });
    });

    test('v22 → v23  adds notes to version', () async {
      await checkUpgrade(22, 23, (db) async {
        expect(await columnNames(db, 'version'), contains('notes'));
      });
    });

    test('v23 → v24  creates cloud_version_note table', () async {
      await checkUpgrade(23, 24, (db) async {
        expect(await tableNames(db), contains('cloud_version_note'));
      });
    });

    test('v24 → v25  adds title to cloud_version_note', () async {
      await checkUpgrade(24, 25, (db) async {
        expect(await columnNames(db, 'cloud_version_note'), contains('title'));
      });
    });

    test('v25 → v26  creates cloud_version_key_overwrite', () async {
      await checkUpgrade(25, 26, (db) async {
        expect(await tableNames(db), contains('cloud_version_key_overwrite'));
      });
    });

    test('Full path v16 → v26 succeeds', () async {
      await checkUpgrade(16, 26, (db) async {
        expect(
          await tableNames(db),
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
      });
    });
  });
}
