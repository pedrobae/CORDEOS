// test/domain/cipher_test.dart
//
// Tests for the Cipher domain object (parsing, validation, equality, etc.).

import 'package:flutter_test/flutter_test.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';

void register() {
  group('Cipher (domain)', () {
    // ── fromMap / toMap ───────────────────────────────────────────────────────
    test('fromMap produces correct fields', () async {
      final map = {
        'id': 1,
        'title': 'Hallelujah',
        'language': 'por',
        'cipher_text': 'L1v1ng7h3m4g1c',
        'author': 'Leonard',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
      };
      final cipher = Cipher.fromSqLite(map);
      expect(cipher.title, 'Hallelujah');
      expect(cipher.language, 'por');
    });

    test('toMap round-trips correctly', () async {
      final cipher = Cipher.fromSqLite({
        'id': 1,
        'title': 'Hallelujah',
        'language': 'por',
        'cipher_text': 'L1v1ng7h3m4g1c',
        'author': 'Leonard',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
      });
      expect(cipher.toSqLite()['title'], cipher.title);
    });

    // ── validation ────────────────────────────────────────────────────────────
    test('title must not be empty', () async {
      expect(
        () => Cipher(
          title: '',
          id: 1,
          author: '',
          musicKey: '',
          language: '',
          createdAt: DateTime.now(),
          isLocal: true,
        ),
        throwsArgumentError,
      );
    });

    // ── equality / copyWith ───────────────────────────────────────────────────
    test('copyWith updates only the specified field', () async {
      final a = Cipher(
        id: 1,
        title: 'Original',
        author: '',
        musicKey: '',
        language: '',
        createdAt: DateTime.now(),
        isLocal: true,
      );
      final b = a.copyWith(title: 'Updated');
      expect(b.title, 'Updated');
      expect(b.id, a.id);
    });
  });
}
