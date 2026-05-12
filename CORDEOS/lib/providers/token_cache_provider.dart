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
  Map<String, Measurements> getMeasurements() => _measurementCache;

  /// Phase 3: content|style|layout → positions
  final Map<String, TokenPositionMap> _positionCache = {};
  TokenPositionMap? getPositions(
    TokenCacheKey key,
    TextStyle chordStyle,
    TextStyle lyricStyle,
  ) => _positionCache[positionCacheKey(key, chordStyle, lyricStyle)];

  /// Phase 4a: content|style|layout|color → paintModel (view mode only)
  final Map<String, SectionPaintModel> _paintCache = {};
  SectionPaintModel? getPaintModel(
    TokenCacheKey key,
    TextStyle chordStyle,
    TextStyle lyricStyle,
  ) => _paintCache[paintCacheKey(key, chordStyle, lyricStyle)];

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
      key.content!,
      showLyrics: key.showLyrics ?? true,
      showChords: key.showChords ?? true,
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
    required TokenCacheKey key,
  }) {
    final tokens = getTokens(key);
    if (tokens == null) {
      return;
    }
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.chord:
          final msrKey = measurementKey(
            token.text,
            chordStyle,
            isChordToken: key.isEditMode,
          );
          if (_measurementCache.containsKey(msrKey)) {
            break;
          }
          final msr = _builder.measureText(
            text: token.text,
            style: chordStyle,
            isChordToken: key.isEditMode,
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
            height: msr.height + chordMsr.height + key.heightSpacing!,
            baseline: msr.baseline,
            size: msr.size + chordMsr.size,
          );
          break;

        case TokenType.preChordTarget:
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
        case TokenType.postChordTarget:
          final msrKey = chordTargetKey(token.text, chordStyle, lyricStyle);
          if (_measurementCache.containsKey(msrKey)) {
            break;
          }
          final msr = _builder.measureText(
            text: '&',
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
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
  }) {
    final cacheKey = positionCacheKey(key, chordStyle, lyricStyle);
    if (_positionCache.containsKey(cacheKey)) {
      return;
    }

    final lyricHeight = _builder
        .measureText(style: lyricStyle, text: 'Sample Text')
        .height;
    final chordHeight = _builder
        .measureText(style: chordStyle, text: 'C', isChordToken: key.isEditMode)
        .height;

    // Cache miss - compute
    final positions = _positioner.calculateTokenPositions(
      organizedTokens: getOrganized(key)!,
      measurements: _measurementCache,
      maxWidth: key.maxWidth!,
      heightSpacing: key.heightSpacing!,
      minChordSpacing: key.minChordSpacing!,
      letterSpacing: key.letterSpacing!,
      isEditMode: key.isEditMode,
      lyricStyle: lyricStyle,
      chordStyle: chordStyle,
      lyricHeight: lyricHeight,
      chordHeight: chordHeight,
      showChords: key.showChords ?? true,
      showLyrics: key.showLyrics ?? true,
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
    required Function(
      ContentToken,
      ContentToken, {
      bool addBefore,
      bool isChordTarget,
    })
    onAddChord,
    required Function(ContentToken) onRemoveChord,
  }) {
    final chordHeight = _builder
        .measureText(style: chordStyle, text: 'C', isChordToken: true)
        .height;
    final lyricHeight = _builder
        .measureText(style: lyricStyle, text: 'Sample Text')
        .height;

    final OrganizedWidgets contentWidgets = _builder.buildEditWidgets(
      tokens: getTokens(key)!,
      organizedTokens: getOrganized(key)!,
      measurements: _measurementCache,
      tokenPositions: getPositions(key, chordStyle, lyricStyle)!,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      maxWidth: key.maxWidth!,
      chordTargetColor: chordTargetColor,
      surfaceColor: surfaceColor,
      onSurfaceColor: onSurfaceColor,
      contentColor: contentColor,
      onContentColor: onContentColor,
      isEnabled: isEnabled,
      onAddChord: onAddChord,
      onRemoveChord: onRemoveChord,
      lineHeight: lyricHeight + key.heightSpacing! + chordHeight,
      chordHeight: chordHeight,
      toggleDrag: _toggleDragging(),
    );

    final positionedContent = _positioner.applyPositionsToWidgets(
      contentWidgets,
      getPositions(key, chordStyle, lyricStyle)!,
      key.isEditMode,
    );
    return positionedContent;
  }

  /// View mode paint caching
  void cachePaintInstructions(
    TokenCacheKey key,
    TextStyle lyricStyle,
    TextStyle chordStyle,
  ) {
    final cacheKey = paintCacheKey(key, chordStyle, lyricStyle);
    if (_paintCache.containsKey(cacheKey)) {
      return;
    }

    final model = _builder.buildPaintModel(
      sectionKey: key.sectionKey,
      measurements: _measurementCache,
      positions: getPositions(key, chordStyle, lyricStyle)!,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      chordColor: key.chordColor!,
      lyricColor: key.lyricColor!,
    );

    _paintCache[cacheKey] = model;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  String getContent(TokenCacheKey key) {
    final content = _tokenizer.reconstructContent(getTokens(key)!);
    return content;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT EDITING
  // ═══════════════════════════════════════════════════════════════════════════
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
    debugPrint("TOKEN PROVIDER - clearing caches");
    _tokenCache.clear();
    _organizedCache.clear();
    _measurementCache.clear();
    _positionCache.clear();
    _paintCache.clear();
  }

  void clearSectionKey(TokenCacheKey key) {
    debugPrint("TOKEN PROVIDER - clearing cache of section ${key.sectionKey}");
    _tokenCache.removeWhere((k, v) => k.startsWith(key.sectionKey.toString()));
    _organizedCache.removeWhere(
      (k, v) => k.startsWith(key.sectionKey.toString()),
    );
    _measurementCache.removeWhere(
      (k, v) => k.startsWith(key.sectionKey.toString()),
    );
    _positionCache.removeWhere(
      (k, v) => k.startsWith(key.sectionKey.toString()),
    );
    _paintCache.removeWhere((k, v) => k.startsWith(key.sectionKey.toString()));
  }

  void invalidatePaintCache(TokenCacheKey key) {
    _paintCache.removeWhere((k, v) => k.startsWith(tokenCacheKey(key)));
  }

  /// Invalidates position cache only (when layout settings change).
  void invalidatePositions(TokenCacheKey key) {
    _positionCache.removeWhere((k, v) => k.startsWith(tokenCacheKey(key)));
    invalidatePaintCache(key); // Paint depends on positions
  }
}
