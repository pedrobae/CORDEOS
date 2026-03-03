import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks/mock_providers.dart';

/// Test utilities for common widget test operations
class TestUtils {
  /// Wraps a widget with necessary providers for testing
  static Widget wrapWithProviders(
    Widget child, {
    MockCipherProvider? cipherProvider,
    MockLocalVersionProvider? localVersionProvider,
    MockCloudVersionProvider? cloudVersionProvider,
    MockSectionProvider? sectionProvider,
    MockPlaylistProvider? playlistProvider,
    MockAuthProvider? authProvider,
    MockUserProvider? userProvider,
    MockNavigationProvider? navigationProvider,
    MockSettingsProvider? settingsProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MockSettingsProvider>(
          create: (_) => settingsProvider ?? MockSettingsProvider(),
        ),
        ChangeNotifierProvider<MockAuthProvider>(
          create: (_) => authProvider ?? MockAuthProvider(),
        ),
        ChangeNotifierProvider<MockNavigationProvider>(
          create: (_) => navigationProvider ?? MockNavigationProvider(),
        ),
        ChangeNotifierProvider<MockCipherProvider>(
          create: (_) => cipherProvider ?? MockCipherProvider(),
        ),
        ChangeNotifierProvider<MockLocalVersionProvider>(
          create: (_) => localVersionProvider ?? MockLocalVersionProvider(),
        ),
        ChangeNotifierProvider<MockCloudVersionProvider>(
          create: (_) => cloudVersionProvider ?? MockCloudVersionProvider(),
        ),
        ChangeNotifierProvider<MockSectionProvider>(
          create: (_) => sectionProvider ?? MockSectionProvider(),
        ),
        ChangeNotifierProvider<MockPlaylistProvider>(
          create: (_) => playlistProvider ?? MockPlaylistProvider(),
        ),
        ChangeNotifierProvider<MockUserProvider>(
          create: (_) => userProvider ?? MockUserProvider(),
        ),
      ],
      child: MaterialApp(
        home: child,
        localizationsDelegates: const [
          // Add your localization delegates here
        ],
      ),
    );
  }

  /// Finds a button by text label
  static Finder findButton(WidgetTester tester, String label) {
    return find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.text(label),
    );
  }

  /// Taps a button and settles the animation
  static Future<void> tapButton(
    WidgetTester tester,
    String label,
  ) async {
    await tester.tap(findButton(tester, label));
    await tester.pumpAndSettle();
  }

  /// Pops a dialog by tapping outside or on close button
  static Future<void> closeDialog(WidgetTester tester) async {
    await tester.tap(find.byType(MaterialButton).first);
    await tester.pumpAndSettle();
  }

  /// Fills a text field with value
  static Future<void> fillTextField(
    WidgetTester tester,
    String hintOrLabel,
    String value,
  ) async {
    final textFieldFinder = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          (widget.decoration?.hintText == hintOrLabel ||
              widget.decoration?.labelText == hintOrLabel),
    );

    expect(textFieldFinder, findsWidgets);
    await tester.enterText(textFieldFinder.first, value);
    await tester.pump();
  }

  /// Waits for a widget to appear
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpWidget(Container()); // Reset
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Scrolls to find a specific widget
  static Future<void> scrollToFind(
    WidgetTester tester,
    Finder finder,
  ) async {
    while (!finder.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(finder, 300);
      await tester.pumpAndSettle();
    }
  }

  /// Verifies widget is visible
  static void expectWidgetVisible(Finder finder) {
    expect(finder, findsWidgets);
  }

  /// Verifies widget is not visible
  static void expectWidgetNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies text is displayed
  static void expectTextVisible(String text) {
    expect(find.text(text), findsWidgets);
  }

  /// Waits for loading to complete
  static Future<void> waitForLoading(WidgetTester tester) async {
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Extension methods for convenient testing
extension WidgetTesterX on WidgetTester {
  /// Taps button by label
  Future<void> tapButtonWithText(String label) async {
    await tap(find.text(label));
    await pumpAndSettle();
  }

  /// Enters text into field with hint
  Future<void> enterTextInField(String hint, String text) async {
    await enterText(find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == hint,
    ), text);
    await pump();
  }

  /// Verifies text exists
  void expectText(String text) {
    expect(find.text(text), findsWidgets);
  }

  /// Verifies text doesn't exist
  void expectNoText(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Waits for any pending animations
  Future<void> waitForAnimations() => pumpAndSettle();

  /// Opens a dialog and returns the content finder
  Future<void> openDialog(String buttonText) async {
    await tapButtonWithText(buttonText);
    await pumpAndSettle();
  }

  /// Closes currently open dialog
  Future<void> closeCurrentDialog() async {
    await tapButtonWithText('Cancel');
    await waitForAnimations();
  }
}
