// test/widgets/cipher_card_test.dart
//
// Widget tests — pump a widget, verify render and interactions.
// Use pumpWidget with a minimal MaterialApp wrapper.
//
// TEMPLATE: copy, rename, fill in.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:cordeos/widgets/cipher_card.dart';
// import 'package:cordeos/domain/cipher.dart';

void register() {
  group('CipherCard widget', () {
    // Convenience wrapper so widgets have a valid MediaQuery / Directionality
    Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('displays cipher title', (tester) async {
      // await tester.pumpWidget(_wrap(
      //   CipherCard(cipher: Cipher(id: 1, title: 'Hallelujah')),
      // ));
      // expect(find.text('Hallelujah'), findsOneWidget);
    });

    testWidgets('tapping card triggers onTap callback', (tester) async {
      // bool tapped = false;
      // await tester.pumpWidget(_wrap(
      //   CipherCard(
      //     cipher: Cipher(id: 1, title: 'Test'),
      //     onTap: () => tapped = true,
      //   ),
      // ));
      // await tester.tap(find.byType(CipherCard));
      // expect(tapped, isTrue);
    });
  });
}
