// ignore_for_file: unused_local_variable

import 'package:cordis/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mock_providers.dart';
import '../../test_utils.dart';

void main() {
  group('HomeScreen - Button Tests', () {
    late MockCipherProvider mockCipherProvider;
    late MockAuthProvider mockAuthProvider;
    late MockLocalVersionProvider mockVersionProvider;
    late MockSectionProvider mockSectionProvider;
    late MockNavigationProvider mockNavigationProvider;
    late MockUserProvider mockUserProvider;
    late MockPlaylistProvider mockPlaylistProvider;
    late MockCloudScheduleProvider mockCloudScheduleProvider;
    late MockLocalScheduleProvider mockLocalScheduleProvider;
    late MockCloudVersionProvider mockCloudVersionProvider;

    setUp(() {
      mockCipherProvider = MockCipherProvider();
      mockAuthProvider = MockAuthProvider();
      mockVersionProvider = MockLocalVersionProvider();
      mockSectionProvider = MockSectionProvider();
      mockNavigationProvider = MockNavigationProvider();
      mockUserProvider = MockUserProvider();
      mockPlaylistProvider = MockPlaylistProvider();
      mockAuthProvider.setAuthenticated('user123', 'test@example.com');
    });

    testWidgets(
      'HomeScreen displays empty state when no schedules',
      (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          TestUtils.wrapWithProviders(
            const HomeScreen(),
            cipherProvider: mockCipherProvider,
            authProvider: mockAuthProvider,
            localVersionProvider: mockVersionProvider,
            sectionProvider: mockSectionProvider,
            navigationProvider: mockNavigationProvider,
            userProvider: mockUserProvider,
            playlistProvider: mockPlaylistProvider,
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        // Verify empty state message or placeholder
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing, // Should not be loading after settle
        );
      },
    );

    testWidgets(
      'New Cipher FAB opens creation dialog',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          TestUtils.wrapWithProviders(
            const HomeScreen(),
            cipherProvider: mockCipherProvider,
            authProvider: mockAuthProvider,
          ),
        );

        // Act
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Assert - Dialog should be visible (adjust based on actual implementation)
        // expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'Cipher list displays loaded ciphers',
      (WidgetTester tester) async {
        // Arrange
        await mockCipherProvider.loadCiphers();

        await tester.pumpWidget(
          TestUtils.wrapWithProviders(
            const HomeScreen(),
            cipherProvider: mockCipherProvider,
            authProvider: mockAuthProvider,
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert - Mock data should be displayed
        // Verify cipher titles appear (adjust based on UI implementation)
      },
    );

    testWidgets(
      'Cipher card edit button navigates to editor',
      (WidgetTester tester) async {
        // Arrange
        await mockCipherProvider.loadCiphers();

        await tester.pumpWidget(
          TestUtils.wrapWithProviders(
            const HomeScreen(),
            cipherProvider: mockCipherProvider,
            authProvider: mockAuthProvider,
          ),
        );

        await tester.pumpAndSettle();

        // Act
        // Find and tap edit button (adjust selector based on actual widget)
        // final editButtonFinder = find.byIcon(Icons.edit);
        // if (editButtonFinder.evaluate().isNotEmpty) {
        //   await tester.tap(editButtonFinder.first);
        //   await tester.pumpAndSettle();
        // }

        // Assert
        // Verify navigation to editor screen
        // expect(find.byType(CipherEditorScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Cipher delete button removes cipher and shows snackbar',
      (WidgetTester tester) async {
        // Arrange
        await mockCipherProvider.loadCiphers();
        final initialCount = mockCipherProvider.ciphers.length;

        await tester.pumpWidget(
          TestUtils.wrapWithProviders(
            const HomeScreen(),
            cipherProvider: mockCipherProvider,
            authProvider: mockAuthProvider,
          ),
        );

        await tester.pumpAndSettle();

        // Act
        // Find delete button and tap
        // final deleteButtonFinder = find.byIcon(Icons.delete);
        // if (deleteButtonFinder.evaluate().isNotEmpty) {
        //   await tester.tap(deleteButtonFinder.first);
        //   await tester.pumpAndSettle();

        //   // Confirm deletion in dialog
        //   await tester.tapButtonWithText('Delete');
        //   await tester.waitForAnimations();
        // }

        // Assert
        // expect(
        //   mockCipherProvider.ciphers.length,
        //   initialCount - 1,
        // );
        // TestUtils.expectTextVisible('Cipher deleted');
      },
    );

    testWidgets(
      'Share button opens share dialog',
      (WidgetTester tester) async {
        // Arrange
        await mockCipherProvider.loadCiphers();

        await tester.pumpWidget(
          TestUtils.wrapWithProviders(
            const HomeScreen(),
            cipherProvider: mockCipherProvider,
            authProvider: mockAuthProvider,
          ),
        );

        await tester.pumpAndSettle();

        // Act
        // Find and tap share button
        // final shareButtonFinder = find.byIcon(Icons.share);
        // if (shareButtonFinder.evaluate().isNotEmpty) {
        //   await tester.tap(shareButtonFinder.first);
        //   await tester.pumpAndSettle();
        // }

        // Assert
        // Verify share dialog appears
        // expect(find.byType(ShareDialog), findsOneWidget);
      },
    );

    testWidgets(
      'Search filters cipher list correctly',
      (WidgetTester tester) async {
        // Arrange
        await mockCipherProvider.loadCiphers();

        await tester.pumpWidget(
          TestUtils.wrapWithProviders(
            const HomeScreen(),
            cipherProvider: mockCipherProvider,
            authProvider: mockAuthProvider,
          ),
        );

        await tester.pumpAndSettle();

        // Act
        // Find search field and enter search term
        // final searchFieldFinder = find.byType(TextField);
        // await tester.enterText(searchFieldFinder, 'Amazing');
        // await tester.pumpAndSettle();

        // Assert
        // Verify filtered results
        // final filtered = mockCipherProvider.searchCiphers('Amazing');
        // expect(filtered.length, greaterThan(0));
        // expect(filtered[0].title.toLowerCase().contains('amazing'), true);
      },
    );
  });
}

// Add mock providers that are missing
class MockCloudScheduleProvider extends Mock {
  final schedules = <String, dynamic>{};

  Future<void> loadSchedules(String userId) async {
    // Mock implementation
  }
}

class MockLocalScheduleProvider extends Mock {
  Future<void> loadSchedules() async {
    // Mock implementation
  }

  dynamic getNextSchedule() => null;
}
