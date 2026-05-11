import 'dart:async';
import 'package:cordeos/services/key_recognizer_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/repositories/local/cipher_repository.dart';

class CipherProvider extends ChangeNotifier {
  final CipherRepository _cipherRepository = CipherRepository();
  final KeyRecognizerService _recognizer = KeyRecognizerService();

  CipherProvider() {
    clearSearch();
  }

  final Map<int, Cipher> _ciphers = {};

  String _searchTerm = '';

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _hasLoadedCiphers = false;

  String? _error;

  // Getters
  Map<int, Cipher> get ciphers => _ciphers;
  Map<int, String> get filteredCipherIds {
    if (_searchTerm.isEmpty) {
      return _ciphers.map((id, cipher) => MapEntry(id, cipher.title));
    } else {
      final Map<int, String> tempMap = {};
      for (var entry in _ciphers.entries) {
        final cipher = entry.value;
        if (cipher.title.toLowerCase().contains(_searchTerm) ||
            cipher.author.toLowerCase().contains(_searchTerm) ||
            cipher.tags.any((tag) => tag.toLowerCase().contains(_searchTerm))) {
          tempMap[entry.key] = cipher.title;
        }
      }
      return tempMap;
    }
  }

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
      debugPrint('CIPHER - No new cipher to create in local cache');
      return null;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();
    int? cipherId;

    try {
      // Insert basic cipher info and tags
      cipherId = await _cipherRepository.insertPrunedCipher(_ciphers[-1]!);

      _ciphers[cipherId] = _ciphers[-1]!.copyWith(id: cipherId);
      debugPrint('CIPHER - Created a new cipher with id $cipherId');
    } catch (e) {
      _error = e.toString();
      debugPrint('CIPHER - Error creating cipher: $e');
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
  /// Ensure cipher is loaded
  Future<void> ensureIsLoaded(int cipherID) async {
    if (ciphers[cipherID] != null) return;
    try {
      Cipher loadedCipher = (await _cipherRepository.getCipherById(cipherID))!;
      if (loadedCipher.musicKey.isEmpty) {
        final recognizedKey = await _recognizer.recognizeKeyLocal(cipherID);
        loadedCipher = loadedCipher.copyWith(musicKey: recognizedKey);
        await _cipherRepository.updateCipher(loadedCipher);
      }

      _ciphers[cipherID] = loadedCipher;
    } catch (e) {
      debugPrint('CIPHER - Error loading cipher: $e');
    }
  }

  /// Load ciphers from local SQLite
  Future<void> loadCiphers({bool forceReload = false}) async {
    if (_hasLoadedCiphers && !forceReload) {
      debugPrint('CIPHER - Ciphers already loaded, skipping reload');
      return;
    }

    _ciphers.clear();
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
      _hasLoadedCiphers = true;
      debugPrint('CIPHER - Loaded ${_ciphers.length} ciphers');
    } catch (e) {
      _error = e.toString();
      debugPrint('CIPHER - Error loading ciphers: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Load single cipher by ID into cache (_current_cipher)
  Future<void> loadCipher(int cipherId) async {
    if (cipherId == -1) {
      _ciphers.remove(-1);
      return;
    }

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
      debugPrint('CIPHER - Error loading cipher: $e');
    } finally {
      _hasUnsavedChanges = false;
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

      debugPrint(
        'CIPHER - Upserted cipher with Title ${cipher.title} - Cipher ID: $cipherId',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('CIPHER - Error upserting cipher: $e');
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
      debugPrint('CIPHER - Error saving cipher: $e');
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
    String? language,
    List<String>? links,
  }) {
    _ciphers[cipherId] = _ciphers[cipherId]!.copyWith(
      title: title?.trim(),
      author: author?.trim(),
      language: language,
      links: links,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void cacheAddTag(int cipherId, String tag) {
    final currentTags = _ciphers[cipherId]?.tags ?? [];
    if (!currentTags.contains(tag)) {
      final updatedTags = List<String>.from(currentTags)..add(tag);
      _ciphers[cipherId] = _ciphers[cipherId]!.copyWith(tags: updatedTags);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void cacheRemoveTag(int cipherId, String tag) {
    final currentTags = _ciphers[cipherId]?.tags ?? [];
    if (currentTags.contains(tag)) {
      final updatedTags = List<String>.from(currentTags)..remove(tag);
      _ciphers[cipherId] = _ciphers[cipherId]!.copyWith(tags: updatedTags);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void cacheMusicKey(int cipherId, String musicKey) {
    _ciphers[cipherId] = _ciphers[cipherId]!.copyWith(musicKey: musicKey);
    _hasUnsavedChanges = true;
    notifyListeners();
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
      debugPrint('CIPHER - Error deleting cipher: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearCipherFromCache({int? cipherId = -1}) {
    _ciphers.remove(cipherId);
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // ===== UTILS =====
  /// Clear cached data and reset state for debugging
  void clearCache() {
    _ciphers.clear();
    _isSaving = false;
    _hasUnsavedChanges = false;
    _error = null;
    _searchTerm = '';
    notifyListeners();
  }

  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
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
}
