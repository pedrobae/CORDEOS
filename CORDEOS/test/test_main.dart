// test/test_main.dart
//
// Single entry point for the full test suite.
// Run everything:   flutter test test/test_main.dart
// Run one layer:    flutter test test/database/
//
// ── How to add a new layer ────────────────────────────────────────────────────
// 1. Create test/your_layer/your_thing_test.dart  (see existing files as templates)
// 2. Export a top-level void registerYourThingTests() function that contains
//    all group() / test() calls — no setUpAll inside those files.
// 3. Import it here and call it inside main() below the shared setUpAll.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ── Database layer ────────────────────────────────────────────────────────────
import 'database/schema_test.dart' as db_schema;
import 'database/crud_test.dart' as db_crud;
import 'database/migration_test.dart' as db_migration;

// ── Domain layer ──────────────────────────────────────────────────────────────
// import 'domain/cipher_test.dart' as domain_cipher;
// import 'domain/version_test.dart' as domain_version;

// ── Repository layer ──────────────────────────────────────────────────────────
// import 'repositories/cipher_repository_test.dart' as repo_cipher;

// ── Service layer ─────────────────────────────────────────────────────────────
// import 'services/sync_service_test.dart' as svc_sync;

// ── Provider / state layer ────────────────────────────────────────────────────
// import 'providers/cipher_provider_test.dart' as prov_cipher;

// ── Widget layer ──────────────────────────────────────────────────────────────
// import 'widgets/cipher_card_test.dart' as wgt_cipher_card;

void main() {
  // ── Shared one-time setup (runs once for the whole suite) ──────────────────
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── Database ───────────────────────────────────────────────────────────────
  group('Database', () {
    db_schema.register();
    db_crud.register();
    db_migration.register();
  });

  // ── Domain ─────────────────────────────────────────────────────────────────
  // group('Domain', () {
  //   domain_cipher.register();
  //   domain_version.register();
  // });

  // ── Repositories ───────────────────────────────────────────────────────────
  // group('Repositories', () {
  //   repo_cipher.register();
  // });

  // ── Services ───────────────────────────────────────────────────────────────
  // group('Services', () {
  //   svc_sync.register();
  // });

  // ── Providers ──────────────────────────────────────────────────────────────
  // group('Providers', () {
  //   prov_cipher.register();
  // });

  // ── Widgets ────────────────────────────────────────────────────────────────
  // group('Widgets', () {
  //   wgt_cipher_card.register();
  // });
}
