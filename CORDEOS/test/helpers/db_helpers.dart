// test/helpers/db_helpers.dart
//
// Shared utilities for any test that touches SQLite.
// Import this wherever you need a live in-memory database.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cordeos/helpers/database.dart' as app_sqlite;

/// Opens a brand-new in-memory database at [version] using the app's onCreate.
Future<Database> createFreshDb(int version) => openDatabase(
      inMemoryDatabasePath,
      version: version,
      onCreate: (db, v) => app_sqlite.DatabaseHelper().testOnCreate(db, v),
    );

/// Creates a DB at [fromVersion], closes it, then reopens targeting [toVersion]
/// so that onUpgrade fires — mirrors what happens on a real device update.
Future<Database> upgradeDb(int fromVersion, int toVersion) async {
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: fromVersion,
    onCreate: (db, v) => app_sqlite.DatabaseHelper().testOnCreate(db, v),
  );
  await db.close();

  return openDatabase(
    inMemoryDatabasePath,
    version: toVersion,
    onCreate: (db, v) => app_sqlite.DatabaseHelper().testOnCreate(db, v),
    onUpgrade: (db, oldV, newV) =>
        app_sqlite.DatabaseHelper().testOnUpgrade(db, oldV, newV),
  );
}

/// All user-visible table names in [db] (excludes SQLite internals).
Future<List<String>> tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master "
    "WHERE type='table' "
    "AND name NOT LIKE 'sqlite_%' "
    "AND name NOT LIKE 'android_%'",
  );
  return rows.map((r) => r['name'] as String).toList();
}

/// Column names for [table] in [db].
Future<List<String>> columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name'] as String).toList();
}
