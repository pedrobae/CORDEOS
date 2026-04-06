import 'package:cordeos/services/tokenization/build_service.dart';
import 'package:cordeos/services/tokenization/tokenization_service.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/services/tokenization/position_service.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:flutter/material.dart';

/// The provider decides when to compute vs return cached data.
/// Services handle the actual computation (pure functions).
///
/// Phases:
/// 1. Tokenize: content → tokens
/// 2. Organize: tokens → organized
/// 3. Measure: text + style → measurements
/// 4. Position: organized + measurements + constraints → positions
/// 5. Build: positions → widgets (handled by UI with BuildService)
class TokenProvider extends ChangeNotifier {
  // Services (pure computation)
  static const _tokenizer = TokenizationService();
  static const _builder = TokenizationBuilder();
  static const _positioner = PositionService();

  bool _isDragging = false;
  bool get isDragging => _isDragging;
  bool _hasChanges = false;
  bool get hasChanges => _hasChanges;
  // ═══════════════════════════════════════════════════════════════════════════
  // CACHES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Phase 1: content → tokens
  final Map<String, List<ContentToken>> _tokenCache = {};
  List<ContentToken>? getTokens(TokenCacheKey key) =>
      _tokenCache[tokenCacheKey(key)];

  /// Phase 1: content → organized tokens
  final Map<String, OrganizedTokens> _organizedCache = {};
  OrganizedTokens? getOrganized(TokenCacheKey key) =>
      _organizedCache[tokenCacheKey(key)];

  /// Phase 2: content|style → measurements (shared across all content)
  final Map<String, Measurements> _measurementCache = {};

  /// Phase 3: content|style|layout → positions
  final Map<String, TokenPositionMap> _positionCache = {};
  TokenPositionMap? getCachedPositions(TokenCacheKey key, bool isEditMode) =>
      _positionCache[positionCacheKey(key, isEditMode)];

  double _chordHeight = 0;
  double _lyricHeight = 0;
  double lineHeight(TokenCacheKey key, bool isEditMode) {
    return _lyricHeight +
        key.chordLyricSpacing! +
        (isEditMode
            ? _chordHeight + 2 * TokenizationConstants.chordTokenHeightPadding
            : _chordHeight);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 1: TOKENIZE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Computes tokens for the given key if not already cached.
  /// key must include all parameters that affect tokenization (content + filters + transposition).
  void tokenize(
    TokenCacheKey key, {
    required String Function(String) transposeChord,
  }) {
    if (getTokens(key) != null) {
      return;
    }

    // Cache miss - compute
    final tokens = _tokenizer.tokenize(
      key.content,
      showLyrics: key.showLyrics!,
      showChords: key.showChords!,
      transposeChord: transposeChord,
    );

    _tokenCache[tokenCacheKey(key)] = tokens;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 1: ORGANIZE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Organizes tokens for the given key if not already cached.
  /// Must be called after tokenize() to ensure tokens are available.
  void organize(TokenCacheKey key) {
    if (getOrganized(key) != null) {
      return;
    }

    final tokens = getTokens(key)!;

    final organized = _tokenizer.organize(tokens);
    _organizedCache[tokenCacheKey(key)] = organized;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 2: MEASURE
  // ═══════════════════════════════════════════════════════════════════════════
  /// Measures tokens for the given key.
  /// Key must include chordLyricSpacing.
  /// Tokens are already transposed, so we just measure text as-is.
  /// Uses cache where available, computes and caches where needed.
  void measureTokens({
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required bool isEditMode,
    required TokenCacheKey key,
  }) {
    final tokens = getTokens(key);
    if (tokens == null) {
      return;
    }
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.chord:
          if (_chordHeight == 0) {
            final msr = _builder.measureText(
              text: token.text,
              style: chordStyle,
              isChordToken: isEditMode,
            );
            _chordHeight = msr.height;
          }

          final msrKey = measurementKey(
            token.text,
            chordStyle,
            isChordToken: isEditMode,
          );
          if (_measurementCache.containsKey(msrKey)) {
            break;
          }
          final msr = _builder.measureText(
            text: token.text,
            style: chordStyle,
            isChordToken: isEditMode,
          );

          _measurementCache[msrKey] = msr;
          break;
        case TokenType.space:
        case TokenType.lyric:
          final msrKey = measurementKey(token.text, lyricStyle);
          if (_measurementCache.containsKey(msrKey)) {
            break;
          }
          final msr = _builder.measureText(text: token.text, style: lyricStyle);
          if (_lyricHeight == 0) {
            _lyricHeight = msr.height;
          }
          _measurementCache[msrKey] = msr;
          break;
        case TokenType.preSeparator:
        case TokenType.postSeparator:
          final msrKey = separatorKey(chordStyle, lyricStyle);
          if (_measurementCache.containsKey(msrKey)) {
            break;
          }
          final msr = _builder.measureText(text: '<>', style: lyricStyle);
          final chordMsr = _builder.measureText(
            text: 'C',
            style: chordStyle,
            isChordToken: true,
          );
          _measurementCache[msrKey] = Measurements(
            width: TokenizationConstants.targetWidth,
            height: msr.height + chordMsr.height + key.chordLyricSpacing!,
            baseline: msr.baseline,
            size: msr.size + chordMsr.size,
          );
          break;

        case TokenType.chordTarget:
          final msrKey = chordTargetKey(token.text, chordStyle, lyricStyle);
          if (_measurementCache.containsKey(msrKey)) {
            break;
          }
          final msr = _builder.measureText(
            text: '@',
            style: lyricStyle,
            isChordToken: false,
          );
          final chordMsr = _builder.measureText(
            text: token.text,
            style: chordStyle,
            isChordToken: true,
          );
          _measurementCache[msrKey] = Measurements(
            width: chordMsr.width,
            height: msr.height,
            baseline: msr.baseline,
            size: msr.size,
          );
          break;
        case TokenType.underline:
        case TokenType.newline:
          // Dynamic, computed during positioning
          break;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 3: POSITION
  // ═══════════════════════════════════════════════════════════════════════════
  /// Calculates positions and caches them.
  /// key must include all necessary layout parameters.
  /// Uses cache where available, computes and caches where needed.
  void calculatePositions({
    required TokenCacheKey key,
    required bool isEditMode,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
  }) {
    final cacheKey = positionCacheKey(key, isEditMode);
    if (_positionCache.containsKey(cacheKey)) {
      return;
    }

    // Cache miss - compute
    final positions = _positioner.calculateTokenPositions(
      organizedTokens: getOrganized(key)!,
      measurements: _measurementCache,
      maxWidth: key.maxWidth!,
      lineSpacing: key.lineSpacing!,
      lineBreakSpacing: key.lineBreakSpacing!,
      chordLyricSpacing: key.chordLyricSpacing!,
      minChordSpacing: key.minChordSpacing!,
      letterSpacing: key.letterSpacing!,
      lineHeight: lineHeight(key, isEditMode),
      chordHeight: _chordHeight,
      lyricHeight: _lyricHeight,
      isEditMode: isEditMode,
      lyricStyle: lyricStyle,
      chordStyle: chordStyle,
    );

    // Cache results
    _positionCache[cacheKey] = positions;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 4: BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  /// Builds and applies positions to widgets, returning the final positioned content.
  /// Key must include all necessary layout parameters.
  ContentTokenized buildEditWidgets({
    required TokenCacheKey key,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
    required Color chordTargetColor,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required Color contentColor,
    required Color onContentColor,
    required bool isEnabled,
    required bool isEditMode,
  }) {
    final OrganizedWidgets contentWidgets = _builder.buildEditWidgets(
      tokens: getTokens(key)!,
      organizedTokens: getOrganized(key)!,
      measurements: _measurementCache,
      tokenPositions: getCachedPositions(key, true)!,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      maxWidth: key.maxWidth!,
      lineHeight: lineHeight(key, true),
      chordHeight: _chordHeight,
      chordTargetColor: chordTargetColor,
      surfaceColor: surfaceColor,
      onSurfaceColor: onSurfaceColor,
      contentColor: contentColor,
      onContentColor: onContentColor,
      isEnabled: isEnabled,
      onAddChord: _addChord(key),
      onRemoveChord: removeChord(key),
      toggleDrag: _toggleDragging(),
    );

    final positionedContent = _positioner.applyPositionsToWidgets(
      contentWidgets,
      getCachedPositions(key, true)!,
      lineHeight(key, true),
      _chordHeight,
      isEditMode,
    );
    return positionedContent;
  }

  ContentTokenized buildViewWidgets({
    required TokenCacheKey key,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
    required Color textColor,
    required Color chordColor,
  }) {
    final contentWidgets = _builder.buildViewWidgets(
      tokens: getTokens(key)!,
      organizedTokens: getOrganized(key)!,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      lineHeight: lineHeight(key, false),
      textColor: textColor,
      chordColor: chordColor,
      measurements: _measurementCache,
    );

    final positionedContent = _positioner.applyPositionsToWidgets(
      contentWidgets,
      getCachedPositions(key, false)!,
      lineHeight(key, false),
      _chordHeight,
      false,
    );
    return positionedContent;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  String getContent(TokenCacheKey key) {
    final content = _tokenizer.reconstructContent(getTokens(key)!);
    return content;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT EDITING
  // ═══════════════════════════════════════════════════════════════════════════
  /// Adds a chord at the specified position, modifying the token cache and invalidating downstream caches
  /// Position is the index of the token to which the chord should be attached
  Function(ContentToken, ContentToken) _addChord(TokenCacheKey key) {
    return (ContentToken targetToken, ContentToken chordToken) {
      _hasChanges = true;
      final cache = getTokens(key);
      if (cache == null) return;
      // Insert chord token immediately before the target token
      final index = cache.indexOf(targetToken);
      if (index >= 0 && index < cache.length) {
        cache.insert(index, chordToken);
      }
      // Invalidate downstream caches
      _organizedCache.remove(tokenCacheKey(key));
      _positionCache.remove(positionCacheKey(key, true));
    };
  }

  Function(ContentToken) removeChord(TokenCacheKey key) {
    return (ContentToken draggable) {
      _hasChanges = true;
      final cache = getTokens(key);
      if (cache == null) return;

      final index = cache.indexOf(draggable);
      if (index >= 0 && index < cache.length) {
        cache.removeAt(index);
      }
    };
  }

  VoidCallback _toggleDragging() {
    return () {
      _isDragging = !_isDragging;
      notifyListeners();
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════
  void clear() {
    _tokenCache.clear();
    _organizedCache.clear();
    _measurementCache.clear();
    _positionCache.clear();
  }

  /// Invalidates position cache only (when layout settings change).
  void invalidatePositions() {
    _positionCache.clear();
  }

  /// Invalidates measurement cache only (when text styles change).
  void invalidateMeasurements() {
    _measurementCache.clear();
    _chordHeight = 0;
    _lyricHeight = 0;
    invalidatePositions(); // Positions depend on measurements
  }
}
