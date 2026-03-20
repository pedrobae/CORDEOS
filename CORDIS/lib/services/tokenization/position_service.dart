import 'dart:math';

import 'package:cordis/services/tokenization/build_service.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
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

  static const _builder = TokenizationBuilder();

  /// Calculates positions for all tokens in the organized structure.
  ///
  /// Takes organized tokens and their measurements, calculates x,y coordinates
  /// using the layout algorithm, and returns a flat position map.
  ///
  /// This allows features like drag feedback to access final positions during build.
  TokenPositionMap calculateTokenPositions({
    required OrganizedTokens organizedTokens,
    required PositioningContext posCtx,
    required TokenBuildContext buildCtx,
    required Map<ContentToken, Measurements> tokenMsr,
  }) {
    final chordMsr = _builder.measureText(
      text: 'teste',
      style: buildCtx.chordStyle,
    );
    final lyricMsr = _builder.measureText(
      text: 'teste',
      style: buildCtx.lyricStyle,
    );

    final precedingOffset = _calculatePrecedingChordOffset(
      organizedTokens,
      tokenMsr,
      posCtx,
    );

    if (posCtx.isEditMode) {
      chordMsr.size += 2 * TokenizationConstants.chordTokenHeightPadding;
    }

    final lineHeight = chordMsr.size + lyricMsr.size + posCtx.chordLyricSpacing;

    final ctx = _LayoutCtx(
      chordHeight: chordMsr.size,
      lyricMsr: lyricMsr,
      precedingOffset: precedingOffset,
      posCtx: posCtx,
      tokenMsr: tokenMsr,
    );

    final cursor = _LayoutCursor(
      precedingOffset: precedingOffset,
      lineHeight: lineHeight,
    );

    final positionMap = TokenPositionMap();

    for (var line in organizedTokens.lines) {
      for (var word in line.words) {
        // Initial pass — detects overflow.
        _WordLayoutResult result = _layoutWord(
          word: word,
          cursor: cursor,
          ctx: ctx,
        );

        if (result.lineBroke) {
          // Word overflowed: bump Y and redo layout from the new line origin.
          cursor.breakLine(ctx.posCtx.lineBreakSpacing);

          result = _layoutWord(word: word, cursor: cursor, ctx: ctx.asReflow());
        }

        // MUTATE
        positionMap.merge(result.wordPositions);
        for (var entry in result.tokensToAdd.entries) {
          word.add(entry.value, entry.key);
        }
      }
      cursor.newLine(ctx.posCtx.lineSpacing);
    }

    return positionMap;
  }

  /// Lays out a single [word]'s tokens into positioned records.
  ///
  /// Mutates [cursor] in-place with advanced x positions after the word.
  /// On overflow the caller calls [cursor.reset] and re-invokes with
  /// [ctx.asReflow()] to reposition on the new line.
  _WordLayoutResult _layoutWord({
    required TokenWord word,
    required _LayoutCursor cursor,
    required _LayoutCtx ctx,
  }) {
    final positions = TokenPositionMap();
    final tokensToAdd = <int, ContentToken>{};
    int charIndex = 0;

    for (var token in word.tokens) {
      final msr = ctx.tokenMsr[token];
      if (msr == null) continue;

      switch (token.type) {
        case TokenType.postSeparator:
          final xOffset = max(
            cursor.chordX - TokenizationConstants.chordTokenWidthPadding,
            cursor.lyricsX,
          );
          if (ctx.posCtx.isEditMode) {
            cursor.chordX =
                xOffset +
                TokenizationConstants.targetWidth +
                2 * ctx.posCtx.minChordSpacing +
                TokenizationConstants.chordTokenWidthPadding;
          } else {
            cursor.chordX = xOffset + ctx.posCtx.minChordSpacing;
          }
          positions.setPosition(
            token,
            xOffset + ctx.posCtx.minChordSpacing,
            cursor.yOffset,
          );

          charIndex++;
          break;

        case TokenType.preSeparator:
          cursor.lyricsX = ctx.precedingOffset + ctx.posCtx.minChordSpacing;
          cursor.chordX = ctx.precedingOffset + ctx.posCtx.minChordSpacing;
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
                cursor.yOffset + ctx.posCtx.chordLyricSpacing + ctx.chordHeight,
              );

              ctx.tokenMsr[underlineToken] = Measurements(
                width: cursor.chordX - cursor.lyricsX,
                height: ctx.lyricMsr.height,
                baseline: ctx.lyricMsr.baseline,
                size: ctx.lyricMsr.size,
              );

              tokensToAdd[charIndex] = underlineToken;
              charIndex++;
            }

            cursor.lyricsX = cursor.chordX;
          }
          positions.setPosition(
            token,
            cursor.lyricsX -
                (ctx.posCtx.isEditMode
                    ? TokenizationConstants.chordTokenWidthPadding
                    : 0),
            cursor.yOffset,
          );

          cursor.chordX =
              cursor.lyricsX + msr.width + ctx.posCtx.minChordSpacing;

          charIndex++;

          if (ctx.checkOverflow && cursor.chordX > ctx.posCtx.maxWidth) {
            return _WordLayoutResult(
              wordPositions: positions,
              tokensToAdd: tokensToAdd,
              lineBroke: true,
            );
          }
          break;

        case TokenType.lyric:
          final xOffset = max(ctx.precedingOffset, cursor.lyricsX);
          if (ctx.posCtx.isEditMode && !ctx.loggedLyricYDebug) {
            ctx.loggedLyricYDebug = true;
          }
          positions.setPosition(
            token,
            xOffset,
            cursor.yOffset + ctx.posCtx.chordLyricSpacing + ctx.chordHeight,
          );
          cursor.lyricsX = xOffset + msr.width + ctx.posCtx.letterSpacing;

          charIndex++;
          if (ctx.checkOverflow && cursor.lyricsX > ctx.posCtx.maxWidth) {
            return _WordLayoutResult(
              wordPositions: positions,
              tokensToAdd: tokensToAdd,
              lineBroke: true,
            );
          }
          break;

        case TokenType.space:
          positions.setPosition(
            token,
            cursor.lyricsX,
            cursor.yOffset + ctx.posCtx.chordLyricSpacing + ctx.chordHeight,
          );
          cursor.lyricsX += msr.width + ctx.posCtx.letterSpacing;
          charIndex++;
          if (ctx.checkOverflow && cursor.lyricsX > ctx.posCtx.maxWidth) {
            return _WordLayoutResult(
              wordPositions: positions,
              tokensToAdd: tokensToAdd,
              lineBroke: true,
            );
          }
          break;

        case TokenType.chordTarget:
          positions.setPosition(
            token,
            cursor.chordX -
                (ctx.posCtx.isEditMode
                    ? TokenizationConstants.chordTokenWidthPadding
                    : 0),
            cursor.yOffset + ctx.posCtx.chordLyricSpacing + ctx.chordHeight,
          );

          charIndex++;
          break;
        // Underlines are injected on-demand above; newlines are handled at
        // the line level — neither should appear during word iteration.
        case TokenType.underline:
        case TokenType.newline:
          break;
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
    Map<ContentToken, Measurements> tokenMeasurements,
    TokenPositionMap positionMap,
    PositioningContext posCtx,
    TokenBuildContext buildCtx,
  ) {
    final chordMsr = _builder.measureText(
      text: 'teste',
      style: buildCtx.chordStyle,
    );
    if (posCtx.isEditMode) {
      chordMsr.size += 2 * TokenizationConstants.chordTokenHeightPadding;
    }

    final tokenWidgets = <Positioned>[];
    double maxY = chordMsr.size + posCtx.chordLyricSpacing;
    // Iterate through widgets and tokens together to get both widget and position
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

          // Track max Y for total height
          maxY = max(maxY, y + tokenMeasurements[tokenWidget.token]!.height);
        }
      }
    }

    return ContentTokenized(tokenWidgets, maxY);
  }

  /// Calculates preceding chord offset.
  /// Preceding chords are indicated with a space before lyrics
  /// [C]lyrics -> 0
  /// [C] lyrics -> len([C])
  /// [C] [D]lyrics -> len([C])
  /// [C] [D] [E]lyrics -> len([C] [D])
  double _calculatePrecedingChordOffset(
    OrganizedTokens contentTokens,
    Map<ContentToken, Measurements> tokenMeasurements,
    PositioningContext ctx,
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
            if (ctx.isEditMode) {
              lineChordX += TokenizationConstants.targetWidth;
            }
            break;
          } else if (token.type == TokenType.chord) {
            // Accumulate all widths
            lineChordX += tokenMeasurements[token]?.width ?? 0.0;
          } else {
            lineLyricX += tokenMeasurements[token]?.width ?? 0.0;
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
  final Measurements lyricMsr;
  final double chordHeight;
  final double precedingOffset;
  final PositioningContext posCtx;
  final Map<ContentToken, Measurements> tokenMsr;
  final bool checkOverflow;
  bool loggedLyricYDebug;

  _LayoutCtx({
    required this.lyricMsr,
    required this.chordHeight,
    required this.precedingOffset,
    required this.posCtx,
    required this.tokenMsr,
    this.checkOverflow = true,
    this.loggedLyricYDebug = false,
  });

  /// Returns a copy with [checkOverflow] disabled for the reflow pass.
  _LayoutCtx asReflow() => _LayoutCtx(
    lyricMsr: lyricMsr,
    chordHeight: chordHeight,
    precedingOffset: precedingOffset,
    posCtx: posCtx,
    tokenMsr: tokenMsr,
    checkOverflow: false,
    loggedLyricYDebug: loggedLyricYDebug,
  );
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

  _LayoutCursor({required this.precedingOffset, required this.lineHeight});

  /// Starts a fresh visual line at origin.
  void breakLine(double lineBreakSpacing) {
    yOffset += lineHeight + lineBreakSpacing;
    lyricsX = precedingOffset;
    chordX = precedingOffset;
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
