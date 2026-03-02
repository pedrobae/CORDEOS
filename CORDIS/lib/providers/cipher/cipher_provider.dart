import 'dart:async';
import 'package:cordis/services/key_recognizer_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/repositories/local/cipher_repository.dart';

class CipherProvider extends ChangeNotifier {
  final CipherRepository _cipherRepository = CipherRepository();
  final KeyRecognizerService _recognizer = KeyRecognizerService();

  CipherProvider() {
    clearSearch();
  }

  final Map<int, Cipher> _ciphers = {};

  String _searchTerm = '';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  String? _error;

  // Getters
  Map<int, Cipher> get ciphers => _ciphers;
  List<int> get filteredCipherIds {
    if (_searchTerm.isEmpty) {
      return _ciphers.keys.toList();
    } else {
      final List<int> tempList = [];
      for (var entry in _ciphers.entries) {
        final cipher = entry.value;
        if (cipher.title.toLowerCase().contains(_searchTerm) ||
            cipher.author.toLowerCase().contains(_searchTerm) ||
            cipher.tags.any((tag) => tag.toLowerCase().contains(_searchTerm))) {
          tempList.add(entry.key);
        }
      }
      return tempList;
    }
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  String? get error => _error;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// USED WHEN UPSERTING VERSIONS FROM CLOUD (as ciphers are not stored in cloud)
  int? getCipherIdByTitleOrAuthor(String title, String author) {
    return _ciphers.values
        .firstWhere(
          (cipher) => cipher.title == title && cipher.author == author,
          orElse: () => Cipher.empty(),
        )
        .id;
  }

  // ===== CREATE =====
  /// Creates a new cipher in the database from the cached new cipher (-1)
  Future<int?> createCipher() async {
    if (_isSaving) return null;
    if (_ciphers[-1] == null) {
      if (kDebugMode) {
        print('No new cipher to create in local cache');
      }
      return null;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();
    int? cipherId;

    try {
      // Insert basic cipher info and tags
      cipherId = await _cipherRepository.insertPrunedCipher(_ciphers[-1]!);

      // Load the new ID into the cache
      _ciphers[cipherId] = _ciphers[-1]!.copyWith(id: cipherId);
      if (kDebugMode) {
        print('Created a new cipher with id $cipherId');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating cipher: $e');
      }
    } finally {
      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
    return cipherId;
  }

  void setNewCipherInCache(Cipher cipher) {
    _ciphers[-1] = cipher;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  // ===== READ =====
  /// Load ciphers from local SQLite
  Future<void> loadCiphers({bool forceReload = false}) async {
    if (_isLoading) return;
    // Debounce rapid calls
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prunedCiphers = await _cipherRepository.getAllCiphersPruned();

      for (var cipher in prunedCiphers) {
        if (cipher.musicKey.isEmpty) {
          final recognizedKey = await _recognizer.recognizeKeyLocal(cipher.id);
          cipher = cipher.copyWith(musicKey: recognizedKey);
          await _cipherRepository.updateCipher(cipher);
        }
        _ciphers[cipher.id] = cipher;
      }

      if (kDebugMode) {
        print('Loaded ${_ciphers.length} ciphers from SQLite');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading ciphers: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load single cipher by ID into cache (_current_cipher)
  Future<void> loadCipher(int cipherId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Cipher loadedCipher = (await _cipherRepository.getCipherById(cipherId))!;
      if (loadedCipher.musicKey.isEmpty) {
        final recognizedKey = await _recognizer.recognizeKeyLocal(cipherId);
        loadedCipher = loadedCipher.copyWith(musicKey: recognizedKey);
        await _cipherRepository.updateCipher(loadedCipher);
      }

      _ciphers[cipherId] = loadedCipher;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cipher: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load single cipher into cache by Version Id
  Future<void> loadCipherOfVersion(int versionId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Cipher cipher = (await _cipherRepository.getCipherWithVersionId(
        versionId,
      ))!;
      if (cipher.musicKey.isEmpty) {
        final recognizedKey = await _recognizer.recognizeKeyLocal(cipher.id);
        cipher = cipher.copyWith(musicKey: recognizedKey);
        await _cipherRepository.updateCipher(cipher);
      }
      _ciphers[cipher.id] = cipher;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading cipher of Version: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== UPSERT =====
  /// Upsert a cipher into the database used when syncing a playlist
  /// Returns the local cipher ID
  Future<int> upsertCipher(Cipher cipher) async {
    int cipherId = -1;
    if (_isSaving) return cipherId;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Check if cipher exists on the cache
      cipherId = _ciphers.values
          .firstWhere(
            (cachedCipher) =>
                (cachedCipher.title == cipher.title &&
                cachedCipher.author == cipher.author),
            orElse: () => Cipher.empty(),
          )
          .id;

      if (cipherId != -1) {
        await _cipherRepository.updateCipher(cipher.copyWith(id: cipherId));
      } else {
        cipherId = await _cipherRepository.insertPrunedCipher(cipher);
      }

      if (kDebugMode) {
        print(
          'Upserted cipher with Title ${cipher.title} - Cipher ID: $cipherId',
        );
      }

      // Load the upserted cipher into the cache
      await loadCipher(cipherId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error upserting cipher: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return cipherId;
  }

  // ===== UPDATE =====
  /// Save current cipher changes to database
  Future<void> saveCipher(int cipherId) async {
    if (_isSaving) return;
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Update basic cipher info and tags
      await _cipherRepository.updateCipher(_ciphers[cipherId]!);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error saving cipher: $e');
      }
    } finally {
      _hasUnsavedChanges = false;
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Update cache with non tag changes
  void cacheUpdates(
    int cipherId, {
    String? title,
    String? author,
    String? musicKey,
    String? language,
    List<String>? tags,
  }) {
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

  void addTagtoCache(int cipherId, String tag) {
    final currentTags = _ciphers[cipherId]?.tags ?? [];
    if (!currentTags.contains(tag)) {
      final updatedTags = List<String>.from(currentTags)..add(tag);
      _ciphers[cipherId] = _ciphers[cipherId]!.copyWith(tags: updatedTags);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // ===== DELETE =====
  /// Delete a cipher from the database
  Future<void> deleteCipher(int cipherID) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _cipherRepository.deleteCipher(cipherID);
      // Reload all ciphers to reflect the deletion
      _ciphers.remove(cipherID);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting cipher: $e');
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearNewCipherFromCache() {
    _ciphers.remove(-1);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ===== UTILS =====
  /// Clear cached data and reset state for debugging
  void clearCache() {
    _ciphers.clear();
    _isLoading = false;
    _isSaving = false;
    _hasUnsavedChanges = false;
    _error = null;
    _searchTerm = '';
    notifyListeners();
  }

  void clearSearch() {
    _searchTerm = '';
  }

  /// Sets the search term for filtering ciphers
  Future<void> setSearchTerm(String term) async {
    _searchTerm = term.toLowerCase();
    notifyListeners();
  }

  // ===== CIPHER CACHING =====
  /// Get cipher from cache
  Cipher? getCipher(int cipherId) {
    return _ciphers[cipherId];
  }

  /// Check if a cipher is already cached
  bool cipherIsCached(int cipherId) {
    return _ciphers.containsKey(cipherId);
  }
}
