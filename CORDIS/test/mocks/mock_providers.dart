import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/user.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/playlist/playlist_provider.dart';
import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

import 'mock_data.dart';

// ============================================================================
// CIPHER PROVIDER MOCKS
// ============================================================================

class MockCipherProvider extends Mock implements CipherProvider {
  final _ciphers = <int, Cipher>{1: mockCipherObject, 2: mockCipherObject2};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _error;
  String _searchTerm = '';

  @override
  Map<int, Cipher> get ciphers => _ciphers;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isSaving => _isSaving;

  @override
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  @override
  String? get error => _error;

  @override
  List<int> get filteredCipherIds {
    if (_searchTerm.isEmpty) {
      return _ciphers.keys.toList();
    } else {
      return _ciphers.entries
          .where((entry) =>
              entry.value.title.toLowerCase().contains(_searchTerm) ||
              entry.value.author.toLowerCase().contains(_searchTerm) ||
              entry.value.tags.any((tag) => tag.toLowerCase().contains(_searchTerm)))
          .map((e) => e.key)
          .toList();
    }
  }

  @override
  Future<void> loadCiphers({bool forceReload = false}) async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> loadCipher(int cipherId) async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<int?> createCipher() async {
    if (_isSaving) return null;
    _isSaving = true;
    
    final newId = (_ciphers.keys.isEmpty ? 1 : _ciphers.keys.reduce((a, b) => a > b ? a : b)) + 1;
    _ciphers[newId] = mockCipherObject.copyWith(id: newId, title: 'New Cipher');
    
    _isSaving = false;
    _hasUnsavedChanges = false;
    notifyListeners();
    return newId;
  }

  @override
  Future<void> saveCipher(int cipherId) async {
    if (_isSaving) return;
    _isSaving = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _hasUnsavedChanges = false;
    _isSaving = false;
    notifyListeners();
  }

  @override
  void cacheUpdates(
    int cipherId, {
    String? title,
    String? author,
    String? musicKey,
    String? language,
    List<String>? tags,
  }) {
    if (_ciphers.containsKey(cipherId)) {
      _ciphers[cipherId] = _ciphers[cipherId]!.copyWith(
        title: title,
        author: author,
        musicKey: musicKey,
        language: language,
        tags: tags,
      );
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  @override
  void addTagtoCache(int cipherId, String tag) {
    if (_ciphers.containsKey(cipherId)) {
      final currentTags = _ciphers[cipherId]?.tags ?? [];
      if (!currentTags.contains(tag)) {
        final updatedTags = List<String>.from(currentTags)..add(tag);
        _ciphers[cipherId] = _ciphers[cipherId]!.copyWith(tags: updatedTags);
        _hasUnsavedChanges = true;
        notifyListeners();
      }
    }
  }

  @override
  Future<void> deleteCipher(int cipherID) async {
    if (_isSaving) return;
    _isSaving = true;
    _ciphers.remove(cipherID);
    _isSaving = false;
    notifyListeners();
  }

  @override
  void setNewCipherInCache(Cipher cipher) {
    _ciphers[-1] = cipher;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  @override
  void clearNewCipherFromCache() {
    _ciphers.remove(-1);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  @override
  Cipher? getCipher(int cipherId) => _ciphers[cipherId];

  @override
  bool cipherIsCached(int cipherId) => _ciphers.containsKey(cipherId);

  @override
  Future<int> upsertCipher(Cipher cipher) async {
    _isSaving = true;
    final newId = (_ciphers.keys.isEmpty ? 1 : _ciphers.keys.reduce((a, b) => a > b ? a : b)) + 1;
    _ciphers[newId] = cipher.copyWith(id: newId);
    _isSaving = false;
    notifyListeners();
    return newId;
  }

  @override
  void clearCache() {
    _ciphers.clear();
    _isLoading = false;
    _isSaving = false;
    _hasUnsavedChanges = false;
    _error = null;
    _searchTerm = '';
    notifyListeners();
  }

  @override
  Future<void> setSearchTerm(String term) async {
    _searchTerm = term.toLowerCase();
    notifyListeners();
  }

  @override
  int? getCipherIdByTitleOrAuthor(String title, String author) {
    return _ciphers.values
        .firstWhere(
          (cipher) => cipher.title == title && cipher.author == author,
          orElse: () => Cipher.empty(),
        )
        .id;
  }
}

// ============================================================================
// VERSION PROVIDER MOCKS
// ============================================================================

class MockLocalVersionProvider extends Mock
    implements LocalVersionProvider {
  final _versions = <int, Version>{1: mockVersionObject, 2: mockVersionObject2};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _error;

  @override
  Map<int, Version> get versions => _versions;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isSaving => _isSaving;

  @override
  String? get error => _error;

  @override
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  @override
  int get localVersionCount {
    if (_versions[-1] != null) {
      return _versions.length - 1;
    }
    return _versions.length;
  }

  @override
  Version? cachedVersion(int versionId) => _versions[versionId];

  @override
  Future<Version?> getVersion(int versionID) async {
    return _versions[versionID];
  }

  @override
  Future<Version?> getVersionByFirebaseId(String firebaseId) async {
    try {
      return _versions.values.firstWhere((v) => v.firebaseId == firebaseId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<int> getVersionsByCipherId(int cipherId) {
    return _versions.values
        .where((version) => version.cipherId == cipherId)
        .map((version) => version.id!)
        .toList();
  }

  @override
  int getVersionsOfCipherCount(int cipherId) {
    return _versions.values.where((version) => version.cipherId == cipherId).length;
  }

  @override
  Future<void> loadVersionsOfCipher(int cipherId) async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> loadVersion(int versionId) async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<int?> createVersion({int? cipherID}) async {
    if (_isSaving) return null;
    _isSaving = true;
    
    final newId = (_versions.keys.isEmpty ? 1 : _versions.keys.reduce((a, b) => a > b ? a : b)) + 1;
    _versions[newId] = mockVersionObject.copyWith(id: newId, cipherId: cipherID ?? 1);
    
    _isSaving = false;
    _hasUnsavedChanges = false;
    notifyListeners();
    return newId;
  }

  @override
  void setNewVersionInCache(Version version) {
    _versions[-1] = version;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  @override
  Future<int> upsertVersion(Version version) async {
    _isSaving = true;
    final newId = version.id ?? (_versions.keys.isEmpty ? 1 : _versions.keys.reduce((a, b) => a > b ? a : b)) + 1;
    _versions[newId] = version.copyWith(id: newId);
    _isSaving = false;
    notifyListeners();
    return newId;
  }

  @override
  Future<void> updateVersion(Version version) async {
    if (_isSaving) return;
    _isSaving = true;
    if (version.id != null) {
      _versions[version.id!] = version;
    }
    _isSaving = false;
    notifyListeners();
  }

  @override
  Future<void> cacheSongStructure(int versionId, List<String> songStructure) async {
    if (_versions.containsKey(versionId)) {
      _versions[versionId] = _versions[versionId]!.copyWith(songStructure: songStructure);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  @override
  void reorderSongStructure(int versionId, int oldIndex, int newIndex) {
    if (_versions.containsKey(versionId)) {
      final structure = List<String>.from(_versions[versionId]!.songStructure);
      final item = structure.removeAt(oldIndex);
      structure.insert(newIndex, item);
      _versions[versionId] = _versions[versionId]!.copyWith(songStructure: structure);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  @override
  void addSectionToStruct(int versionId, String contentCode) {
    if (_versions.containsKey(versionId)) {
      final structure = List<String>.from(_versions[versionId]!.songStructure);
      structure.add(contentCode);
      _versions[versionId] = _versions[versionId]!.copyWith(songStructure: structure);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  @override
  void removeSectionFromStructByCode(int versionId, String contentCode) {
    if (_versions.containsKey(versionId)) {
      final structure = List<String>.from(_versions[versionId]!.songStructure);
      structure.removeWhere((code) => code == contentCode);
      _versions[versionId] = _versions[versionId]!.copyWith(songStructure: structure);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  @override
  Future<void> deleteVersion(int versionId) async {
    if (_isSaving) return;
    _isSaving = true;
    _versions.remove(versionId);
    _isSaving = false;
    notifyListeners();
  }

  @override
  Future<void> saveVersion(int versionID) async {
    if (_isSaving) return;
    _isSaving = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _hasUnsavedChanges = false;
    _isSaving = false;
    notifyListeners();
  }

  @override
  void clearCache() {
    _versions.clear();
    _isLoading = false;
    _isSaving = false;
    _hasUnsavedChanges = false;
    _error = null;
    notifyListeners();
  }

  @override
  Future<Version?> fetchVersion(int versionID) async {
    return _versions[versionID];
  }
}

class MockCloudVersionProvider extends Mock
    implements CloudVersionProvider {
  final _versions = <String, VersionDto>{};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _searchTerm = '';

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isSaving => _isSaving;

  @override
  String? get error => _error;

  @override
  Map<String, VersionDto> get versions => _versions;

  @override
  List<String> get filteredCloudVersionIds {
    if (_searchTerm.isEmpty) {
      return _versions.keys.toList();
    } else {
      return _versions.entries
          .where((entry) =>
              entry.value.title.toLowerCase().contains(_searchTerm) == true ||
              entry.value.author.toLowerCase().contains(_searchTerm) == true)
          .map((e) => e.key)
          .toList();
    }
  }

  @override
  Future<void> loadVersions({bool forceReload = false, List<Cipher>? localCiphers}) async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }

  @override
  VersionDto? getVersion(String id) => _versions[id];

  @override
  void setVersion(String firebaseId, dynamic versionData) {
    _versions[firebaseId] = versionData;
    notifyListeners();
  }

  @override
  Future<void> setSearchTerm(String term) async {
    _searchTerm = term.toLowerCase();
    notifyListeners();
  }

  @override
  void clearCache() {
    _versions.clear();
    _isLoading = false;
    _isSaving = false;
    _error = null;
    _searchTerm = '';
    notifyListeners();
  }
}

// ============================================================================
// SECTION PROVIDER MOCKS
// ============================================================================

class MockSectionProvider extends Mock implements SectionProvider {
  final _sections = <dynamic, Map<String, Section>>{
    1: {
      'I': mockSectionIntro,
      'V1': mockSectionVerse,
      'C': mockSectionChorus,
    },
  };
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _error;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isSaving => _isSaving;

  @override
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  @override
  String? get error => _error;

  @override
  Map<String, Section> getSections(dynamic versionKey) {
    return _sections[versionKey] ?? {};
  }

  @override
  Section? getSection(dynamic versionKey, String contentCode) {
    return _sections[versionKey]?[contentCode];
  }

  @override
  String cacheAddSection(
    dynamic versionKey,
    String contentCode,
    Color color,
    String sectionType,
  ) {
    _sections[versionKey] ??= {};
    final newSection = Section(
      versionId: versionKey is String ? -1 : versionKey,
      contentCode: contentCode,
      contentColor: color,
      contentType: sectionType,
      contentText: '',
    );
    _sections[versionKey]![contentCode] = newSection;
    _hasUnsavedChanges = true;
    notifyListeners();
    return contentCode;
  }

  @override
  void setNewSectionsInCache(
    dynamic versionKey,
    Map<String, Section> sections,
  ) {
    _sections[versionKey] = sections;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  @override
  Future<void> createSections(dynamic versionID) async {
    if (_isSaving) return;
    _isSaving = true;
    _sections[versionID] ??= {};
    _isSaving = false;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  @override
  Future<void> saveSections({dynamic versionID}) async {
    if (_isSaving) return;
    _isSaving = true;
    if (_sections.containsKey(versionID)) {
      _sections[versionID] = _sections[versionID]!;
      _hasUnsavedChanges = true;
    }
    _isSaving = false;
    notifyListeners();
  }

  @override
  Future<void> cacheDeleteSection(dynamic versionId, String sectionCode) async {
    if (_isSaving) return;
    _isSaving = true;
    _sections[versionId]?.remove(sectionCode);
    _hasUnsavedChanges = true;
    _isSaving = false;
    notifyListeners();
  }

  @override
  void clearCache() {
    _sections.clear();
    _isLoading = false;
    _isSaving = false;
    _hasUnsavedChanges = false;
    _error = null;
    notifyListeners();
  }

  @override
  String cacheUpdate(dynamic versionId, String contentCode, { Color? newColor,String? newContentCode, String? newContentText, String? newContentType}) {
    if (_sections[versionId]?[contentCode] != null) {
      final section = _sections[versionId]![contentCode]!;
      if (newContentText != null) section.contentText = newContentText;
      if (newContentCode != null) section.contentCode = newContentCode;
      if (newContentType != null) section.contentType = newContentType;
      if (newColor != null) section.contentColor = newColor;
      _hasUnsavedChanges = true;
      notifyListeners();
    }
    return newContentCode ?? contentCode;
  }
}

// ============================================================================
// PLAYLIST PROVIDER MOCKS
// ============================================================================

class MockPlaylistProvider extends Mock implements PlaylistProvider {
  final _playlists = <int, Playlist>{1: mockPlaylistObject};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _hasUnsavedChanges = false;
  String? _error;
  String _searchTerm = '';

  @override
  Map<int, Playlist> get playlists => _playlists;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isSaving => _isSaving;

  @override
  bool get isDeleting => _isDeleting;

  @override
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  @override
  String? get error => _error;

  @override
  List<int> get filteredPlaylists {
    if (_searchTerm.isEmpty) {
      return _playlists.keys.toList();
    } else {
      return _playlists.entries
          .where((entry) => entry.value.name.toLowerCase().contains(_searchTerm))
          .map((e) => e.key)
          .toList();
    }
  }

  @override
  Future<void> loadPlaylists() async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> loadPlaylist(int id) async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }

  @override
  Playlist? getPlaylistById(int id) => _playlists[id];

  @override
  Future<void> createPlaylist(String playlistName, int userLocalId) async {
    if (_isSaving) return;
    
    _isSaving = true;
    final newId = (_playlists.keys.isEmpty ? 1 : _playlists.keys.reduce((a, b) => a > b ? a : b)) + 1;
    _playlists[newId] = Playlist(
      id: newId,
      name: playlistName,
      createdBy: userLocalId,
    );
    _isSaving = false;
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  @override
  Future<int> createPlaylistFromDomain(Playlist playlist) async {
    _isSaving = true;
    final newId = (_playlists.keys.isEmpty ? 1 : _playlists.keys.reduce((a, b) => a > b ? a : b)) + 1;
    _playlists[newId] = playlist.copyWith(id: newId);
    _isSaving = false;
    notifyListeners();
    return newId;
  }

  @override
  void setPlaylist(Playlist playlist) {
    _playlists[playlist.id] = playlist;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  @override
  Future<void> deletePlaylist(int id) async {
    if (_isDeleting) return;
    _isDeleting = true;
    _playlists.remove(id);
    _isDeleting = false;
    notifyListeners();
  }

  @override
  void clearCache() {
    _playlists.clear();
    _isLoading = false;
    _isSaving = false;
    _isDeleting = false;
    _hasUnsavedChanges = false;
    _error = null;
    _searchTerm = '';
    notifyListeners();
  }

  @override
  Future<void> setSearchTerm(String term) async {
    _searchTerm = term.toLowerCase();
    notifyListeners();
  }
}

// ============================================================================
// AUTH PROVIDER MOCKS
// ============================================================================

class MockAuthProvider extends Mock implements MyAuthProvider {
  String? _userId;
  String? _email;
  bool _isAuthenticated = false;

  @override
  String? get id => _userId;

  @override
  String? get userEmail => _email;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<void> signInWithGoogle() async {
    _userId = 'user123';
    _email = 'test@example.com';
    _isAuthenticated = true;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    _email = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void setAuthenticated(String id, String email) {
    _userId = id;
    _email = email;
    _isAuthenticated = true;
    notifyListeners();
  }
}

// ============================================================================
// USER PROVIDER MOCKS
// ============================================================================

class MockUserProvider extends Mock implements UserProvider {
  final _knownUsers = <User>[mockUserObject, mockAdminObject];
  bool _isLoading = false;
  bool _isLoadingCloud = false;
  bool _isSaving = false;
  bool _hasInitialized = false;
  String? _error;

  @override
  List<User> get knownUsers => _knownUsers;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLoadingCloud => _isLoadingCloud;

  @override
  bool get isSaving => _isSaving;

  @override
  bool get hasInitialized => _hasInitialized;

  @override
  String? get error => _error;

  @override
  Future<void> loadUsers() async {
    _isLoading = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _hasInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> downloadUserFromCloud(String firebaseUserId) async {
    if (_isLoadingCloud) return;
    _isLoadingCloud = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoadingCloud = false;
    notifyListeners();
  }

  @override
  Future<void> ensureUserExists(String firebaseUserId) async {
    final exists = _knownUsers.any((u) => u.firebaseId == firebaseUserId);
    if (!exists) {
      _knownUsers.add(
        User(
          firebaseId: firebaseUserId,
          username: 'user_$firebaseUserId',
          email: 'user@example.com',
        ),
      );
      notifyListeners();
    }
  }

  @override
  User? getUserByFirebaseId(String firebaseId) {
    try {
      return _knownUsers.firstWhere((u) => u.firebaseId == firebaseId);
    } catch (e) {
      return null;
    }
  }

  @override
  User? getUserById(int id) {
    try {
      return _knownUsers.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void clearCache() {
    _knownUsers.clear();
    _isLoading = false;
    _isLoadingCloud = false;
    _isSaving = false;
    _hasInitialized = false;
    _error = null;
    notifyListeners();
  }
}

// ============================================================================
// NAVIGATION PROVIDER MOCKS
// ============================================================================

class MockNavigationProvider extends Mock implements NavigationProvider {
  NavigationRoute _currentRoute = NavigationRoute.home;

  @override
  NavigationRoute get currentRoute => _currentRoute;

  @override
  Future<void> attemptPop(BuildContext context,{NavigationRoute? route}) async {
    _currentRoute = NavigationRoute.home;
    notifyListeners();
  }
}

// ============================================================================
// SETTINGS PROVIDER MOCKS
// ============================================================================

class MockSettingsProvider extends Mock implements SettingsProvider {
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'en';

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Locale get locale => Locale(_language);


  @override
  Future<void> loadSettings() async {
    // Load defaults
    notifyListeners();
  }

  @override
  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
  }

  @override
  Future<void> setLocale(Locale code) async {
    _language = code.languageCode;
    notifyListeners();
  }
}
