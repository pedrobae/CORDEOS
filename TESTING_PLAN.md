# Cipher App - Testing Plan

## Overview
This document outlines a comprehensive testing strategy for the Cipher App Flutter project, covering all interactive buttons and user flows with mock data.

## Current State
- **Testing Framework**: Flutter Test + Mockito
- **Existing Tests**: None (from scratch)
- **Test Dependencies**: Already in pubspec.yaml (`flutter_test`, `mockito`)

---

## Testing Architecture

### 1. Test Organization
```
test/
├── unit/
│   ├── providers/
│   │   ├── cipher_provider_test.dart
│   │   ├── version_provider_test.dart
│   │   ├── playlist_provider_test.dart
│   │   ├── section_provider_test.dart
│   │   └── auth_provider_test.dart
│   ├── repositories/
│   │   ├── local_cipher_repository_test.dart
│   │   └── cloud_cipher_repository_test.dart
│   └── utils/
│       ├── color_utils_test.dart
│       └── date_utils_test.dart
│
├── widget/
│   ├── screens/
│   │   ├── home_screen_test.dart
│   │   ├── main_screen_test.dart
│   │   ├── cipher_viewer_screen_test.dart
│   │   ├── cipher_editor_screen_test.dart
│   │   ├── playlist_screen_test.dart
│   │   ├── schedule_screen_test.dart
│   │   ├── settings_screen_test.dart
│   │   └── admin_screen_test.dart
│   ├── widgets/
│   │   ├── cipher_list_test.dart
│   │   ├── section_card_test.dart
│   │   ├── playlist_card_test.dart
│   │   └── schedule_card_test.dart
│   └── dialogs/
│       ├── create_cipher_dialog_test.dart
│       └── delete_confirmation_dialog_test.dart
│
├── integration/
│   ├── cipher_workflow_test.dart
│   ├── playlist_workflow_test.dart
│   ├── schedule_workflow_test.dart
│   └── auth_workflow_test.dart
│
└── mocks/
    ├── mock_repositories.dart
    ├── mock_providers.dart
    ├── mock_data.dart
    └── mock_firebase.dart
```

---

## Testing Strategy by Component

### Phase 1: Unit Tests (Foundation)

#### 1.1 Provider Tests
Test each provider's core functionality without UI:

**Example: CipherProvider Tests**
- `testLoadCiphers()` - Load all ciphers
- `testCreateCipher()` - Add new cipher
- `testUpdateCipher()` - Modify cipher
- `testDeleteCipher()` - Remove cipher
- `testGetCipherById()` - Fetch single cipher
- `testSearchCiphers()` - Filter by criteria
- `testHandleLoadError()` - Error handling

**Example: AuthProvider Tests**
- `testSignInWithGoogle()` - Email auth
- `testSignOut()` - Logout
- `testTokenRefresh()` - Session management
- `testLoadUserProfile()` - User data

#### 1.2 Repository Tests
Mock Firestore and SQLite:

```dart
// Mock Firebase Firestore
final mockFirestore = MockFirebaseFirestore();
final mockAuth = MockFirebaseAuth();

// Test cases
- testGetCipherFromLocal()
- testDownloadCipherFromCloud()
- testSaveToLocal()
- testSyncWithCloud()
```

---

### Phase 2: Widget Tests (UI Interactions)

#### 2.1 Main Navigation Buttons
**MainScreen Buttons:**
- Home navigation button → verify screen change
- Cipher library button → verify list loads
- Playlists button → verify playlists display
- Schedule button → verify schedule shows
- Settings button → verify settings open

#### 2.2 Cipher Management Buttons
**HomeScreen Buttons:**
- "New Cipher" FAB → open add cipher dialog
- "Edit Cipher" button → navigate to editor
- "Delete Cipher" button → confirm and remove
- "Share Cipher" button → show share options
- "Download Cipher" button → fetch from cloud

**CipherViewerScreen Buttons:**
- "Edit" → go to editor
- "Delete" → show confirmation
- "Print/Export" → download PDF
- "Share" → share options
- "Auto-scroll" toggle → enable/disable scrolling
- "Transposition" button → open key picker
- Section navigation buttons → jump to sections

**CipherEditorScreen Buttons:**
- "Save" button → persist changes
- "Cancel" button → abandon changes
- "Add Section" button → new section input
- "Delete Section" button → remove section
- "Reorder" (drag handles) → rearrange items
- Color picker → change section colors
- Key picker → transpose

#### 2.3 Playlist Management Buttons
**PlaylistScreen Buttons:**
- "Create Playlist" FAB → new playlist dialog
- "Edit Playlist" → open editor
- "Delete Playlist" → confirm and remove
- "Add to Playlist" → cipher selection
- "Remove from Playlist" → item deletion
- "Share Playlist" → collaboration setup
- "Reorder Ciphers" → drag to prioritize

#### 2.4 Schedule Buttons
**ScheduleScreen Buttons:**
- "New Schedule" FAB → create schedule
- "Edit Schedule" → modify details
- "Delete Schedule" → confirm removal
- "Present Schedule" → start presentation mode
- "Add to Schedule" → playlist selection
- Play/Pause buttons → control playback
- Next/Previous → navigate items

**PlaySchedulePage Buttons:**
- "Start Presentation" → full-screen mode
- "Stop" → return to normal
- "Auto-scroll" toggle → enable scrolling
- "Next Section" → advance
- "Previous Section" → go back
- "Structure buttons" → jump to sections
- "Transpose" → change key

#### 2.5 Settings Buttons
**SettingsScreen Buttons:**
- Theme toggle (Light/Dark) → change theme
- Language selector → change localization
- Font size slider → adjust text
- Column count (layout) → grid change
- "Clear Cache" button → delete local data
- "Sign Out" button → logout
- "Delete Account" → account removal
- "About" button → info screen
- "Backup" button → export data

#### 2.6 Admin Buttons
**AdminScreen Buttons:**
- "Upload Cipher" → cloud upload
- "Manage Users" → user administration
- "View Analytics" → statistics
- "Approve Shares" → collaboration requests
- Delete buttons (ciphers, users) → removal

---

### Phase 3: Integration Tests (User Flows)

#### 3.1 Complete Workflows
**Cipher Creation Workflow:**
1. Click "New Cipher" button
2. Fill cipher form (title, author, key)
3. Click "Next"
4. Add sections with content
5. Click "Save"
6. Verify cipher in library

**Cipher Playback Workflow:**
1. Open cipher from library
2. Click "Present"
3. Click section buttons to navigate
4. Toggle auto-scroll
5. Transpose key
6. Return to library

**Playlist Collaboration:**
1. Create playlist
2. Click "Share"
3. Enter collaborator email
4. Grant permissions
5. Verify shared in collaborator's app

---

## Mock Data Patterns

### Example Mock Cipher Data
```dart
const mockCipher = {
  'id': 1,
  'title': 'Test Hymn',
  'author': 'Test Composer',
  'musicKey': 'C',
  'language': 'en',
  'tags': ['hymn', 'test'],
  'versions': [
    {
      'id': 1,
      'versionName': 'Arrangement 1',
      'bpm': 120,
      'duration': 180000,
      'sections': {
        'I': {
          'contentCode': 'I',
          'contentType': 'chord',
          'contentText': '[C]Amazing grace',
          'contentColor': Colors.purple.value,
        }
      }
    }
  ]
};
```

### Mock Provider Pattern
```dart
class MockCipherProvider extends Mock implements CipherProvider {
  @override
  Future<void> loadCiphers() async {
    // Return mock data
  }
  
  @override
  List<Cipher> get ciphers => [mockCipher];
}
```

---

## Button Testing Checklist

### Interaction Tests
- [ ] Button tap triggers correct action
- [ ] Loading state shows during async operations
- [ ] Error messages display on failure
- [ ] Success feedback shown (snackbar, navigation)
- [ ] Disabled state when action unavailable

### Navigation Tests
- [ ] Navigation button routes to correct screen
- [ ] Back button returns to previous screen
- [ ] Routes preserve state (data not lost)
- [ ] Deep links work correctly

### Form Submission Tests
- [ ] Validation errors shown when field incomplete
- [ ] Save button persists data
- [ ] Cancel button discards changes
- [ ] Duplicate prevention works

### State Management Tests
- [ ] Provider notifies listeners after action
- [ ] UI updates reflect state changes
- [ ] Multiple rapid clicks don't cause issues (debouncing)
- [ ] Offline buttons still work (local-first)

---

## Test Sample Structure

### Unit Test Template
```dart
import 'package:cordis/providers/cipher_provider.dart';
import 'package:cordis/models/domain/cipher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('CipherProvider', () {
    late CipherProvider provider;
    late MockRepository mockRepository;

    setUp(() {
      mockRepository = MockRepository();
      provider = CipherProvider(repository: mockRepository);
    });

    test('loadCiphers fetches all ciphers', () async {
      when(mockRepository.getAllCipher())
          .thenAnswer((_) async => [mockCipherData]);

      await provider.loadCiphers();

      expect(provider.ciphers.length, 1);
      expect(provider.ciphers[0].title, 'Test Hymn');
    });

    test('createCipher adds new cipher to list', () async {
      when(mockRepository.insertCipher(any))
          .thenAnswer((_) async => 1);

      await provider.createCipher(mockCipherData);

      verify(mockRepository.insertCipher(any)).called(1);
    });
  });
}
```

### Widget Test Template
```dart
import 'package:cordis/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('HomeScreen Buttons', () {
    testWidgets('New Cipher FAB opens dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MockCipherProvider()),
            // ... other providers
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Find and tap FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Edit button navigates to editor', (WidgetTester tester) async {
      // Test setup and navigation
    });
  });
}
```

---

## Implementation Priority

### Phase 1 (Foundation) - Weeks 1-2
1. Set up test infrastructure (mocks, fixtures)
2. Create unit tests for providers
3. Create unit tests for repositories

### Phase 2 (Interactions) - Weeks 3-5
1. Widget tests for navigation buttons
2. Widget tests for form buttons
3. Widget tests for data manipulation buttons

### Phase 3 (Workflows) - Weeks 6-8
1. Integration tests for complete flows
2. Error handling scenarios
3. Edge case coverage

---

## Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/unit/providers/cipher_provider_test.dart

# With coverage
flutter test --coverage
```

---

## Coverage Goals
- **Unit Tests**: 80%+ coverage on providers/repositories
- **Widget Tests**: All interactive buttons tested
- **Integration Tests**: All major user workflows covered
- **Overall Target**: 70%+ code coverage

---

## Future Enhancements
- Performance benchmarks for list rendering
- Golden file tests for UI components
- Accessibility (a11y) testing
- Bluetooth sync testing (when implemented)

