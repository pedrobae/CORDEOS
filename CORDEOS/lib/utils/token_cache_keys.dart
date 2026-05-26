// ═══════════════════════════════════════════════════════════════════════════
// CACHE KEY FOR LAYOUT-DEPENDENT DATA
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Composite key for position cache that includes all layout dependencies.
/// Two keys are equal only if all parameters match.
class TokenCacheKey {
  String? content;
  final int sectionKey;
  double? maxWidth;
  double? heightSpacing;
  double? minChordSpacing;
  double? letterSpacing;
  bool? showChords;
  bool? showChordBass;
  bool? showAddedNotes;
  bool? showLyrics;
  bool? showAnnotations;
  bool isEditMode;
  String? songKey;
  Color? chordColor;
  Color? lyricColor;
  Color? annotationColor;

  TokenCacheKey({
    this.content,
    this.maxWidth,
    this.heightSpacing,
    this.minChordSpacing,
    this.letterSpacing,
    this.showChords,
    this.showLyrics,
    this.showChordBass,
    this.showAddedNotes,
    this.showAnnotations,
    this.songKey,
    required this.sectionKey,
    this.isEditMode = false,
    this.chordColor,
    this.lyricColor,
    this.annotationColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokenCacheKey &&
        other.content == content &&
        other.maxWidth == maxWidth &&
        other.heightSpacing == heightSpacing &&
        other.minChordSpacing == minChordSpacing &&
        other.letterSpacing == letterSpacing &&
        other.showChords == showChords &&
        other.showChordBass == showChordBass &&
        other.showAddedNotes == showAddedNotes &&
        other.showLyrics == showLyrics &&
        other.showAnnotations == showAnnotations &&
        other.isEditMode == isEditMode &&
        other.songKey == songKey &&
        other.sectionKey == sectionKey;
  }

  @override
  int get hashCode => Object.hash(
    content,
    sectionKey,
    maxWidth,
    heightSpacing,
    minChordSpacing,
    letterSpacing,
    showChords,
    showChordBass,
    showAddedNotes,
    showAnnotations,
    showLyrics,
    isEditMode,
    songKey,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CACHE KEY HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Token cache key: content + filters + transposition
String tokenCacheKey(TokenCacheKey k) =>
    '${k.sectionKey}|content:${k.content}|chords:${k.showChords}|lyrics:${k.showLyrics}|bass:${k.showChordBass}|addedNotes:${k.showAddedNotes}|songKey:${k.songKey}|editMode:${k.isEditMode}|annotations:${k.showAnnotations}';

String measurementKey(
  String text,
  TextStyle style, {
  bool isChordToken = false,
}) =>
    '$text|${style.fontFamily}|${style.fontSize}|${style.fontWeight?.value}${isChordToken ? '|chordToken' : ''}';

String separatorKey(TextStyle chordStyle, TextStyle lyricStyle) =>
    'SEP|${lyricStyle.fontFamily}|${chordStyle.fontFamily}|${lyricStyle.fontSize}|${chordStyle.fontSize}';

String chordTargetKey(
  String text,
  TextStyle chordStyle,
  TextStyle lyricStyle,
) =>
    'CT|$text|${chordStyle.fontFamily}|${chordStyle.fontSize}|${lyricStyle.fontSize}';

/// Position cache key: token key + layout params + Style params
String positionCacheKey(
  TokenCacheKey k,
  TextStyle chordStyle,
  TextStyle lyricStyle,
) {
  return '${ //
  tokenCacheKey(k)}|w:${ //
  k.maxWidth}|ls:${ //
  k.heightSpacing}|hs:${ //
  k.minChordSpacing}|lts:${ //
  k.letterSpacing}|lStyle:${ //
  lyricStyle.fontFamily}|lSize:${ //
  lyricStyle.fontSize}|cStyle:${ //
  chordStyle.fontFamily}|cSize:${ //
  chordStyle.fontSize}';
}

String paintCacheKey(
  TokenCacheKey k,
  TextStyle chordStyle,
  TextStyle lyricStyle,
) =>
    '${positionCacheKey(k, chordStyle, lyricStyle)}|chordColor:${ //
    k.chordColor}|lyricColor:${ //
    k.lyricColor}';
