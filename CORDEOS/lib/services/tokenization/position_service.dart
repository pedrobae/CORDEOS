import 'dart:math';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:flutter/material.dart';

/// Service responsible for calculating token positions and applying them to widgets.
///
/// Handles the positioning logic for chords and lyrics:
/// - Line wrapping when content exceeds maxWidth
/// - Chord positioning above lyrics
/// - Preceding chord target offsets
/// - Line breaking and oversized word handling
class PositionService {
  const PositionService();

  /// Calculates positions for all tokens in the organized structure.
  ///
  /// Takes organized tokens and their measurements, calculates x,y coordinates
  /// using the layout algorithm, and returns a flat position map.
  ///
  /// This allows features like drag feedback to access final positions during build.
  TokenPositionMap calculateTokenPositions({
    required OrganizedTokens organizedTokens,
    required Map<String, Measurements> measurements,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
    required double maxWidth,
    required double lineSpacing,
    required double lineBreakSpacing,
    required double chordLyricSpacing,
    required double minChordSpacing,
    required double letterSpacing,
    required double chordHeight,
    required double lyricHeight,
    required bool isEditMode,
    required bool showChords,
  }) {
    final precedingOffset = _calculatePrecedingChordOffset(
      organizedTokens,
      measurements,
      lyricStyle,
      chordStyle,
      isEditMode,
    );

    final lineHeight =
        lyricHeight + (showChords ? (chordLyricSpacing + chordHeight) : 0);

    final ctx = _LayoutCtx(
      chordHeight: chordHeight,
      precedingOffset: precedingOffset,
      measurements: measurements,
      maxWidth: maxWidth,
      lineSpacing: lineSpacing,
      lineBreakSpacing: lineBreakSpacing,
      chordLyricSpacing: chordLyricSpacing,
      minChordSpacing: minChordSpacing,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
    );

    final cursor = _LayoutCursor(
      precedingOffset: precedingOffset,
      lineHeight: lineHeight,
    );

    final positionMap = TokenPositionMap(
      lineHeight: ctx.lineHeight,
      contentWidth: ctx.maxWidth,
    );

    for (var line in organizedTokens.lines) {
      for (var word in line.words) {
        // Initial pass — detects overflow.
        _WordLayoutResult result = _layoutWord(
          isEditMode: isEditMode,
          word: word,
          cursor: cursor,
          ctx: ctx,
        );

        if (result.lineBroke) {
          // Word overflowed: bump Y and redo layout from the new line origin.
          cursor.breakLine(ctx.lineBreakSpacing, isEditMode);

          result = _layoutWord(
            word: word,
            cursor: cursor,
            ctx: ctx,
            isEditMode: isEditMode,
          );
        }

        // MUTATE
        positionMap.merge(result.wordPositions);
        for (var entry in result.tokensToAdd.entries) {
          word.add(entry.value, entry.key);
        }
      }
      cursor.newLine(ctx.lineSpacing);
    }

    positionMap.contentHeight =
        (cursor.yOffset -
                ((cursor.hasLyrics || isEditMode)
                    ? 0
                    : (ctx.lineHeight -
                          ctx.chordHeight -
                          ctx.chordLyricSpacing)))
            .clamp(0, double.infinity);

    return positionMap;
  }

  /// Lays out a single [word]'s tokens into positioned records.
  ///
  /// Mutates [cursor] in-place with advanced x positions after the word.
  /// On overflow the caller calls [cursor.reset] and re-invokes with
  /// [ctx.markReflow()] to reposition on the new line.
  _WordLayoutResult _layoutWord({
    required TokenWord word,
    required _LayoutCursor cursor,
    required _LayoutCtx ctx,
    required bool isEditMode,
  }) {
    final positions = TokenPositionMap(
      lineHeight: ctx.lineHeight,
      contentWidth: ctx.maxWidth,
    );
    final tokensToAdd = <int, ContentToken>{};
    int charIndex = 0;

    for (var token in word.tokens) {
      switch (token.type) {
        case TokenType.postSeparator:
          final xOffset = max(cursor.chordX, cursor.lyricsX);
          if (isEditMode) {
            cursor.chordX =
                xOffset +
                TokenizationConstants.targetWidth +
                ctx.minChordSpacing +
                2 * TokenizationConstants.chordTokenWidthPadding;
          }
          positions.setPosition(token, xOffset, cursor.yOffset);

          charIndex++;
          break;

        case TokenType.preSeparator:
          cursor.lyricsX =
              ctx.precedingOffset +
              (isEditMode ? TokenizationConstants.chordTokenWidthPadding : 0);
          cursor.chordX =
              ctx.precedingOffset +
              (isEditMode ? TokenizationConstants.chordTokenWidthPadding : 0);
          cursor.foundPreSeparator = true;

          positions.setPosition(
            token,
            ctx.precedingOffset - TokenizationConstants.targetWidth,
            cursor.yOffset,
          );
          charIndex++;
          break;

        case TokenType.chord:
          if (cursor.lyricsX < cursor.chordX) {
            // If the chord is ahead of the lyrics,
            // push lyrics forward to the chord,
            // and inject an underline if there are lyrics on both sides of the chord.
            final hasLyricAfter = _hasLyricAfterInWord(word, token);
            final hasLyricBefore = _hasLyricBeforeInWord(word, token);

            if (hasLyricAfter && hasLyricBefore) {
              final underlineToken = ContentToken(
                text: '',
                type: TokenType.underline,
              );

              positions.setPosition(
                underlineToken,
                cursor.lyricsX,
                cursor.yOffset,
              );

              ctx.measurements[underlineToken.toKey()] = Measurements(
                width: cursor.chordX - cursor.lyricsX,
                height: ctx.lineHeight,
                baseline: ctx.chordHeight,
                size: 1,
              );

              tokensToAdd[charIndex] = underlineToken;
              charIndex++;
            }

            cursor.lyricsX = cursor.chordX;
          }
          positions.setPosition(
            token,
            cursor.lyricsX -
                (isEditMode ? TokenizationConstants.chordTokenWidthPadding : 0),
            cursor.yOffset,
          );

          final msr =
              ctx.measurements[measurementKey(
                token.text,
                ctx.chordStyle,
                isChordToken: isEditMode,
              )]!;

          cursor.chordX = cursor.lyricsX + msr.width + ctx.minChordSpacing;

          charIndex++;
          break;

        case TokenType.lyric:
          if (cursor.hasLyrics == false) {
            cursor.hasLyrics = true;
          }
          positions.setPosition(token, cursor.lyricsX, cursor.yOffset);
          final msr =
              ctx.measurements[measurementKey(token.text, ctx.lyricStyle)]!;

          cursor.lyricsX = cursor.lyricsX + msr.width + ctx.letterSpacing;
          charIndex++;
          break;

        case TokenType.space:
          positions.setPosition(token, cursor.lyricsX, cursor.yOffset);

          final msr =
              ctx.measurements[measurementKey(token.text, ctx.lyricStyle)]!;
          cursor.lyricsX += msr.width + ctx.letterSpacing;
          charIndex++;
          break;

        case TokenType.preChordTarget:
        case TokenType.postChordTarget:
          positions.setPosition(
            token,
            cursor.chordX -
                (isEditMode ? TokenizationConstants.chordTokenWidthPadding : 0),
            cursor.yOffset,
          );

          final msr =
              ctx.measurements[chordTargetKey(
                token.text,
                ctx.chordStyle,
                ctx.lyricStyle,
              )]!;

          if (ctx.checkOverflow && (cursor.chordX + msr.width > ctx.maxWidth)) {
            return _WordLayoutResult(
              wordPositions: positions,
              tokensToAdd: tokensToAdd,
              lineBroke: true,
            );
          }

          charIndex++;
          break;
        // Underlines are injected on-demand above; newlines are handled at
        // the line level — neither should appear during word iteration.
        case TokenType.underline:
        case TokenType.newline:
          break;
      }
      if (ctx.checkOverflow &&
          (cursor.lyricsX > ctx.maxWidth || cursor.chordX > ctx.maxWidth)) {
        return _WordLayoutResult(
          wordPositions: positions,
          tokensToAdd: tokensToAdd,
          lineBroke: true,
        );
      }
    }

    return _WordLayoutResult(
      wordPositions: positions,
      tokensToAdd: tokensToAdd,
    );
  }

  /// Applies pre-calculated positions to widgets, creating Positioned widgets.
  ///
  /// Uses the TokenPositionMap to position widgets without recalculating layout.
  /// Handles line breaking and oversized words using position information.
  ContentTokenized applyPositionsToWidgets(
    OrganizedWidgets contentWidgets,
    TokenPositionMap positionMap,
    bool isEditMode,
  ) {
    final tokenWidgets = <Positioned>[];
    for (var widgetLine in contentWidgets.lines) {
      for (var widgetWord in widgetLine.words) {
        for (var tokenWidget in widgetWord.widgets) {
          // Skip newlines
          if (tokenWidget.type == TokenType.newline) {
            continue;
          }
          // Get position from map
          final x = positionMap.getX(tokenWidget.token) ?? 0.0;
          final y = positionMap.getY(tokenWidget.token) ?? 0.0;

          tokenWidgets.add(
            Positioned(left: x, top: y, child: tokenWidget.widget),
          );
        }
      }
    }
    return ContentTokenized(tokenWidgets);
  }

  /// Calculates preceding chord offset.
  /// Preceding chords are indicated with a space before lyrics
  /// [C]lyrics -> 0
  /// [C] lyrics -> len([C])
  /// [C] [D]lyrics -> len([C])
  /// [C] [D] [E]lyrics -> len([C] [D])
  double _calculatePrecedingChordOffset(
    OrganizedTokens contentTokens,
    Map<String, Measurements> measurements,
    TextStyle lyricStyle,
    TextStyle chordStyle,
    bool isEditMode,
  ) {
    double precedingOffset = 0;
    for (var line in contentTokens.lines) {
      double lineChordX = 0;
      double lineLyricX = 0;
      bool foundSeparator = false;

      for (var word in line.words) {
        if (foundSeparator) {
          break;
        }
        for (var token in word.tokens) {
          if (token.type == TokenType.preSeparator) {
            foundSeparator = true;
            if (isEditMode) {
              lineChordX += TokenizationConstants.targetWidth;
            }
            break;
          } else if (token.type == TokenType.chord) {
            // Accumulate all widths
            lineChordX +=
                measurements[measurementKey(
                      token.text,
                      chordStyle,
                      isChordToken: isEditMode,
                    )]
                    ?.width ??
                0.0;
          } else {
            lineLyricX +=
                measurements[measurementKey(
                      token.text,
                      lyricStyle,
                      isChordToken: false,
                    )]
                    ?.width ??
                0.0;
          }
        }
      }
      final offsetCandidate = max(lineChordX, lineLyricX);
      if (offsetCandidate > precedingOffset && foundSeparator) {
        precedingOffset = offsetCandidate;
      }
    }

    return precedingOffset;
  }

  /// Checks whether there is a lyric token after [chordToken] in the same word.
  bool _hasLyricAfterInWord(TokenWord word, ContentToken chordToken) {
    bool foundChord = false;
    for (var token in word.tokens) {
      if (!foundChord) {
        if (token == chordToken) {
          foundChord = true;
        }
        continue;
      }
      if (token.type == TokenType.lyric) {
        return true;
      }
    }

    return false;
  }

  /// Checks whether there is a lyric token after [chordToken] in the same word.
  bool _hasLyricBeforeInWord(TokenWord word, ContentToken chordToken) {
    bool foundChord = false;
    for (var token in word.tokens.reversed) {
      if (!foundChord) {
        if (token == chordToken) {
          foundChord = true;
        }
        continue;
      }
      if (token.type == TokenType.lyric) {
        return true;
      }
    }

    return false;
  }
}

/// Immutable per-invocation layout parameters threaded through
/// [PositionService._layoutWord].
///
/// All spacing and mode flags come from [posCtx]; [lyricMsr] and
/// [precedingOffset] are pre-computed once per [calculateTokenPositions] call.
/// [tokenMsr] is the shared mutable measurement map — underline tokens
/// are added into it during layout.
class _LayoutCtx {
  final double chordHeight;
  final double precedingOffset;
  final Map<String, Measurements> measurements;
  final double maxWidth;
  final double lineSpacing;
  final double lineBreakSpacing;
  final double chordLyricSpacing;
  final double minChordSpacing;
  final double letterSpacing;
  final double lineHeight;
  final TextStyle chordStyle;
  final TextStyle lyricStyle;
  bool checkOverflow = true;

  _LayoutCtx({
    required this.chordHeight,
    required this.precedingOffset,
    required this.measurements,
    required this.maxWidth,
    required this.lineSpacing,
    required this.lineBreakSpacing,
    required this.chordLyricSpacing,
    required this.minChordSpacing,
    required this.letterSpacing,
    required this.lineHeight,
    required this.chordStyle,
    required this.lyricStyle,
  });

  /// Marks the context for reflow, which relaxes overflow checks and allows
  void markReflow() {
    checkOverflow = false;
  }
}

/// Mutable x-axis cursors shared across word layout passes within a line.
///
/// Passed by reference into [PositionService._layoutWord] and mutated
/// in-place. Call [reset] to reposition at [precedingOffset] when a word
/// overflows to the next line.
class _LayoutCursor {
  double yOffset = 0;
  double lyricsX = 0;
  double chordX = 0;
  double precedingOffset;
  double lineHeight;
  bool foundPreSeparator = false;
  bool hasLyrics = false;

  _LayoutCursor({required this.precedingOffset, required this.lineHeight});

  /// Starts a fresh visual line at origin.
  void breakLine(double lineBreakSpacing, bool isEditMode) {
    yOffset += lineHeight + lineBreakSpacing;
    lyricsX =
        precedingOffset +
        (isEditMode ? TokenizationConstants.chordTokenWidthPadding : 0);
    chordX =
        precedingOffset +
        (isEditMode ? TokenizationConstants.chordTokenWidthPadding : 0);
  }

  void newLine(double newLineSpacing) {
    yOffset += lineHeight + newLineSpacing;
    lyricsX = 0;
    chordX = 0;
    foundPreSeparator = false;
  }
}

/// Output of a single word layout pass from [PositionService._layoutWord].
class _WordLayoutResult {
  final TokenPositionMap wordPositions;
  final Map<int, ContentToken> tokensToAdd;
  final bool lineBroke;

  _WordLayoutResult({
    required this.wordPositions,
    required this.tokensToAdd,
    this.lineBroke = false,
  });
}
