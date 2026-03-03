# Quick Start: Writing Tests for Cipher App

## Overview
This guide helps you quickly start writing tests for button interactions and user workflows in the Cipher App.

## File Structure Reference

```
test/
├── mocks/
│   ├── mock_data.dart          ← Mock objects and constants
│   └── mock_providers.dart     ← Mock provider classes
├── widget/
│   ├── screens/
│   │   └── home_screen_test.dart    ← Example widget tests
│   └── ...
├── unit/
│   ├── providers/
│   │   └── ...                 ← Unit tests for business logic
│   └── ...
└── test_utils.dart             ← Helper functions for tests
```

## Quick Start: Writing Your First Test

### 1. Basic Button Click Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_utils.dart';
import '../mocks/mock_providers.dart';
import '../mocks/mock_data.dart';

void main() {
  testWidgets('Button tap triggers action', (WidgetTester tester) async {
    // Setup
    final mockProvider = MockCipherProvider();
    
    // Build widget with mocks
    await tester.pumpWidget(
      TestUtils.wrapWithProviders(
        const MyButtonWidget(),
        cipherProvider: mockProvider,
      ),
    );

    // Tap button
    await tester.tapButtonWithText('Create New');
    await tester.waitForAnimations();

    // Verify result
    tester.expectText('Success');
  });
}
```

### 2. Testing Form Submission

```dart
testWidgets('Form validates and submits', (WidgetTester tester) async {
  final mockProvider = MockCipherProvider();
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const CipherFormWidget(),
      cipherProvider: mockProvider,
    ),
  );

  // Fill form fields
  await tester.enterTextInField('Title', 'Amazing Grace');
  await tester.enterTextInField('Author', 'John Newton');

  // Submit
  await tester.tapButtonWithText('Save');
  await tester.waitForAnimations();

  // Verify
  expect(mockProvider.ciphers.length, 1);
  tester.expectText('Cipher created');
});
```

### 3. Testing Dialog Actions

```dart
testWidgets('Delete dialog confirms action', (WidgetTester tester) async {
  final mockProvider = MockCipherProvider();
  await mockProvider.loadCiphers(); // Load test data
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const CipherListWidget(),
      cipherProvider: mockProvider,
    ),
  );

  // Open delete dialog
  await tester.tap(find.byIcon(Icons.delete).first);
  await tester.pumpAndSettle();

  // Confirm deletion
  await tester.tapButtonWithText('Delete');
  await tester.waitForAnimations();

  // Verify cipher was removed
  expect(mockProvider.ciphers.length, mockCipherList.length - 1);
});
```

### 4. Testing Navigation

```dart
testWidgets('Edit button navigates to editor', (WidgetTester tester) async {
  final mockProvider = MockCipherProvider();
  final mockNavProvider = MockNavigationProvider();
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const MyWidget(),
      cipherProvider: mockProvider,
      navigationProvider: mockNavProvider,
    ),
  );

  // Tap edit button
  await tester.tap(find.byIcon(Icons.edit).first);
  await tester.pumpAndSettle();

  // Verify navigation
  expect(mockNavProvider.currentIndex, 1);
});
```

## Using Mock Data

### Available Mock Objects

```dart
import '../mocks/mock_data.dart';

// Single objects
mockCipherObject          // Complete cipher with all fields
mockVersionObject         // Version with sections
mockPlaylistObject        // Playlist with versions
mockUserObject           // Regular user
mockAdminObject          // Admin user

// Collections
mockCipherList           // List of ciphers
mockVersionList          // List of versions
mockUserList             // List of users

// Raw data (maps)
mockCipherData           // Raw cipher map
mockVersionData          // Raw version map
mockPlaylistData         // Raw playlist map
mockUserData             // Raw user data
```

### Creating Custom Mock Data

```dart
// In your test file
final customCipher = Cipher(
  id: 999,
  title: 'My Test Hymn',
  author: 'Test Author',
  musicKey: 'D',
  language: 'pt',
  tags: ['test'],
  firebaseId: null,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Use in test
final mockProvider = MockCipherProvider();
await mockProvider.createCipher(customCipher);
expect(mockProvider.ciphers.contains(customCipher), true);
```

## Testing Different User Roles

### Regular User Test
```dart
testWidgets('User sees personal ciphers', (WidgetTester tester) async {
  final mockAuth = MockAuthProvider();
  mockAuth.setAuthenticated('user123', 'user@example.com');
  
  // Test with user permissions
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const HomeScreen(),
      authProvider: mockAuth,
    ),
  );
  
  tester.expectText('My Ciphers');
});
```

### Admin User Test
```dart
testWidgets('Admin sees management options', (WidgetTester tester) async {
  final mockAuth = MockAuthProvider();
  mockAuth.setAuthenticated('admin123', 'admin@example.com');
  
  // Test with admin permissions
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const AdminScreen(),
      authProvider: mockAuth,
    ),
  );
  
  tester.expectText('Manage Users');
});
```

## Testing Async Operations

### Loading States

```dart
testWidgets('Shows loading while fetching', (WidgetTester tester) async {
  final mockProvider = MockCipherProvider();
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const DataScreen(),
      cipherProvider: mockProvider,
    ),
  );

  // Should show loading
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for load
  await mockProvider.loadCiphers();
  await tester.pumpAndSettle();

  // Loading should be gone
  expect(find.byType(CircularProgressIndicator), findsNothing);
  
  // Data should be visible
  tester.expectText('Amazing Grace');
});
```

### Error Handling

```dart
testWidgets('Shows error message on failure', (WidgetTester tester) async {
  // Create mock that fails
  final mockProvider = MockCipherProvider();
  
  // Simulate error by not loading data
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const DataScreen(),
      cipherProvider: mockProvider,
    ),
  );

  await tester.pumpAndSettle();

  // Verify error state
  // tester.expectText('Failed to load');
});
```

## Testing List Interactions

### Scrolling and Finding Items

```dart
testWidgets('Can scroll to find cipher', (WidgetTester tester) async {
  final mockProvider = MockCipherProvider();
  await mockProvider.loadCiphers();
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const CipherListScreen(),
      cipherProvider: mockProvider,
    ),
  );

  const targetText = 'How Great Thou Art';
  
  // Scroll until found
  await TestUtils.scrollToFind(
    tester,
    find.text(targetText),
  );

  tester.expectText(targetText);
});
```

### Reordering Items

```dart
testWidgets('Can reorder playlist items', (WidgetTester tester) async {
  final mockProvider = MockPlaylistProvider();
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const ReorderablePlaylistWidget(),
      playlistProvider: mockProvider,
    ),
  );

  // Find draggable item
  final itemFinder = find.byType(ReorderableDragStartListener).first;

  // Drag to new position
  await tester.drag(itemFinder, const Offset(0, 150));
  await tester.pumpAndSettle();

  // Verify order changed
  expect(mockProvider.playlists[0].versions[0].id, isNotNull);
});
```

## Common Testing Patterns

### Pattern 1: Test Dialog Flow
```dart
testWidgets('Complete dialog workflow', (WidgetTester tester) async {
  await tester.openDialog('New Cipher');
  
  await tester.enterTextInField('Title', 'Test');
  await tester.tapButtonWithText('Save');
  
  await tester.waitForAnimations();
  tester.expectText('Cipher created');
});
```

### Pattern 2: Test Settings Change
```dart
testWidgets('Theme toggle updates app', (WidgetTester tester) async {
  final mockSettings = MockSettingsProvider();
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const SettingsScreen(),
      settingsProvider: mockSettings,
    ),
  );

  expect(mockSettings.darkMode, false);

  await tester.tap(find.byType(Switch).first);
  await tester.pumpAndSettle();

  expect(mockSettings.darkMode, true);
});
```

### Pattern 3: Multi-Provider Test
```dart
testWidgets('Cipher and Version work together', (WidgetTester tester) async {
  final cipherProvider = MockCipherProvider();
  final versionProvider = MockLocalVersionProvider();
  
  await tester.pumpWidget(
    TestUtils.wrapWithProviders(
      const CipherEditorScreen(),
      cipherProvider: cipherProvider,
      localVersionProvider: versionProvider,
    ),
  );

  // Both providers work together
  await cipherProvider.loadCiphers();
  await versionProvider.loadVersions();
  
  expect(cipherProvider.ciphers.isNotEmpty, true);
  expect(versionProvider.versions.isNotEmpty, true);
});
```

## Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/widget/screens/home_screen_test.dart

# Watch mode (rerun on changes)
flutter test --watch

# With coverage
flutter test --coverage

# Specific test
flutter test -k "button tap"
```

## Debugging Tips

### Print Provider State
```dart
print('Ciphers: ${mockProvider.ciphers.length}');
print('Error: ${mockProvider.error}');
print('Loading: ${mockProvider.isLoading}');
```

### Check Widget Tree
```dart
await tester.pump();
print(find.byType(ElevatedButton).evaluate().length);
```

### Verify Text Presence
```dart
expect(find.text('Expected Text'), findsOneWidget);  // Must exist exactly once
expect(find.text('Text'), findsWidgets);             // Can exist multiple times
expect(find.text('Text'), findsNothing);             // Must not exist
```

### Wait for Async
```dart
await tester.pumpAndSettle();  // Wait for animations
await Future.delayed(Duration(milliseconds: 100));  // Wait for network
```

## Troubleshooting

### "RenderBox was not laid out"
- Usually means widget missing size constraints
- Check provider is passed correctly
- Ensure `pumpAndSettle()` called after interactions

### "No widget found"
- Verify mock data is loaded
- Check screen actually displays widget
- Use `expect(..., findsOneWidget)` to debug

### "Duplicate global key"
- Use unique keys in lists
- Pattern: `ValueKey('context_${id}_index_${idx}')`

### Test Hangs
- Call `await tester.pumpAndSettle()`
- Add explicit timeout to assertions
- Check for infinite loops in mock

## Next Steps

1. **Start with simple button tests** - Get comfortable with the framework
2. **Add form validation tests** - Test more complex interactions
3. **Build navigation tests** - Verify routing works
4. **Create integration tests** - Test complete user workflows
5. **Implement error scenarios** - Test edge cases

See `TESTING_PLAN.md` for comprehensive testing strategy and buttons to prioritize.
