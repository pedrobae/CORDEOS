import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/user.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:flutter/material.dart';

/// Mock data for testing
/// Use these constants throughout tests to ensure consistency

// ============================================================================
// CIPHER DATA
// ============================================================================

const mockCipherData = {
  'id': 1,
  'title': 'Amazing Grace',
  'author': 'John Newton',
  'music_key': 'C',
  'language': 'en',
  'tags': ['hymn', 'classic'],
  'is_local': true,
  'created_at': 1704067200000, // 2024-01-01
  'updated_at': 1705276800000, // 2024-01-15
};

const mockCipherData2 = {
  'id': 2,
  'title': 'How Great Thou Art',
  'author': 'Carl Boberg',
  'music_key': 'G',
  'language': 'en',
  'tags': ['hymn', 'traditional'],
  'is_local': true,
  'created_at': 1706889600000, // 2024-02-01
  'updated_at': 1707408000000, // 2024-02-08
};

// ============================================================================
// VERSION DATA
// ============================================================================

const mockVersionData = {
  'id': 1,
  'firebase_id': null,
  'cipher_id': 1,
  'version_name': 'Standard Arrangement',
  'bpm': 120,
  'duration': 180, // in seconds
  'transposed_key': null,
  'song_structure': 'I,V1,C,V2,C,B,C,F',
  'created_at': 1704067200000, // 2024-01-01
};

const mockVersionData2 = {
  'id': 2,
  'firebase_id': null,
  'cipher_id': 1,
  'version_name': 'Contemporary',
  'bpm': 140,
  'duration': 210,
  'transposed_key': null,
  'song_structure': 'I,V1,C,V1,C,B,C,C,F',
  'created_at': 1705276800000, // 2024-01-15
};

// ============================================================================
// SECTION DATA
// ============================================================================

final mockSectionIntro = Section(
  id: 1,
  versionId: 1,
  contentCode: 'I',
  contentText: '[C]',
  contentType: 'intro',
  contentColor: Colors.purple,
);

final mockSectionVerse = Section(
  id: 2,
  versionId: 1,
  contentCode: 'V1',
  contentText: '[C]Amazing grace how [F]sweet the [C]sound',
  contentType: 'verse',
  contentColor: Colors.blue,
);

final mockSectionChorus = Section(
  id: 3,
  versionId: 1,
  contentCode: 'C',
  contentText: '[C]I once was [F]lost but [C]now am found',
  contentType: 'chorus',
  contentColor: Colors.red,
);

// ============================================================================
// CIPHER OBJECTS
// ============================================================================

final mockCipherObject = Cipher(
  id: 1,
  title: 'Amazing Grace',
  author: 'John Newton',
  musicKey: 'C',
  language: 'en',
  tags: ['hymn', 'classic'],
  isLocal: true,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 15),
  versions: [mockVersionObject],
);

final mockCipherObject2 = Cipher(
  id: 2,
  title: 'How Great Thou Art',
  author: 'Carl Boberg',
  musicKey: 'G',
  language: 'en',
  tags: ['hymn', 'traditional'],
  isLocal: true,
  createdAt: DateTime(2024, 2, 1),
  updatedAt: DateTime(2024, 2, 10),
  versions: [],
);

// ============================================================================
// VERSION OBJECTS
// ============================================================================

final mockVersionObject = Version(
  id: 1,
  firebaseId: null,
  cipherId: 1,
  versionName: 'Standard',
  bpm: 120,
  duration: const Duration(seconds: 180),
  transposedKey: null,
  songStructure: const ['I', 'V1', 'C', 'V2', 'C', 'B', 'C', 'F'],
  sections: {
    'I': mockSectionIntro,
    'V1': mockSectionVerse,
    'C': mockSectionChorus,
  },
  createdAt: DateTime(2024, 1, 1),
);

final mockVersionObject2 = Version(
  id: 2,
  firebaseId: null,
  cipherId: 1,
  versionName: 'Contemporary',
  bpm: 140,
  duration: const Duration(seconds: 210),
  transposedKey: null,
  songStructure: const ['I', 'V1', 'C', 'V1', 'C', 'B', 'C', 'C', 'F'],
  sections: {},
  createdAt: DateTime(2024, 1, 15),
);

// ============================================================================
// PLAYLIST DATA
// ============================================================================

const mockPlaylistData = {
  'id': 1,
  'name': 'Sunday Service',
  'created_by': 1,
};

final mockPlaylistObject = Playlist(
  id: 1,
  name: 'Sunday Service',
  createdBy: 1,
  items: [],
);

// ============================================================================
// USER DATA
// ============================================================================

const mockUserData = {
  'id': 1,
  'firebase_id': 'user123',
  'username': 'testuser',
  'email': 'test@example.com',
  'profile_photo': null,
  'language': 'en',
  'time_zone': 'UTC',
  'country': 'US',
  'is_active': 1,
  'created_at': 1704067200000,
  'updated_at': 1705276800000,
};

const mockAdminUserData = {
  'id': 2,
  'firebase_id': 'admin123',
  'username': 'adminuser',
  'email': 'admin@example.com',
  'profile_photo': null,
  'language': 'en',
  'time_zone': 'UTC',
  'country': 'US',
  'is_active': 1,
  'created_at': 1704067200000,
  'updated_at': 1705276800000,
};

final mockUserObject = User(
  id: 1,
  firebaseId: 'user123',
  username: 'testuser',
  email: 'test@example.com',
  profilePhoto: null,
  language: 'en',
  timeZone: 'UTC',
  country: 'US',
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 15),
);

final mockAdminObject = User(
  id: 2,
  firebaseId: 'admin123',
  username: 'adminuser',
  email: 'admin@example.com',
  profilePhoto: null,
  language: 'en',
  timeZone: 'UTC',
  country: 'US',
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 15),
);

// ============================================================================
// COLLECTIONS FOR TESTING
// ============================================================================

final mockCipherList = [mockCipherObject, mockCipherObject2];

final mockVersionList = [mockVersionObject];

final mockUserList = [mockUserObject, mockAdminObject];
