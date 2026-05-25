// test/services/sync_service_test.dart
//
// Tests for services — typically require mocking external dependencies
// (Firebase, HTTP, etc.) while using real DB helpers for the local side.
// TODO: SERVICE TESTS

import 'package:flutter_test/flutter_test.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:cordeos/services/sync_service.dart';
// import 'package:cordeos/repositories/cipher_repository.dart';

// class MockCipherRepository extends Mock implements CipherRepository {}

void register() {
  group('SyncService', () {
    // late MockCipherRepository mockRepo;
    // late SyncService service;

    setUp(() {
      // mockRepo = MockCipherRepository();
      // service = SyncService(cipherRepo: mockRepo);
    });

    test('sync pulls remote ciphers and saves them locally', () async {
      // when(() => mockRepo.upsert(any())).thenAnswer((_) async => 1);
      // await service.syncFromCloud([{'title': 'Remote Song'}]);
      // verify(() => mockRepo.upsert(any())).called(1);
    });

    test('sync skips records that are not modified', () async {
      // ...
    });
  });
}
