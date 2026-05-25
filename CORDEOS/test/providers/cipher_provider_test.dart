// test/providers/cipher_provider_test.dart
//
// Tests for Riverpod providers / ChangeNotifiers / Cubits.

// TODO PROVIDER TESTS
import 'package:flutter_test/flutter_test.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';

void register() {
  group('CipherProvider', () {
    // late ProviderContainer container;
    // late MockCipherRepository mockRepo;

    setUp(() {
      // mockRepo = MockCipherRepository();
      // container = ProviderContainer(
      //   overrides: [cipherRepoProvider.overrideWithValue(mockRepo)],
      // );
    });

    // tearDown(() => container.dispose());

    test('initial state is loading', () async {
      // expect(
      //   container.read(cipherListProvider),
      //   const AsyncValue<List<Cipher>>.loading(),
      // );
    });

    test('state becomes data after fetch', () async {
      // when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      // await container.read(cipherListProvider.future);
      // expect(container.read(cipherListProvider).value, isEmpty);
    });
  });
}
