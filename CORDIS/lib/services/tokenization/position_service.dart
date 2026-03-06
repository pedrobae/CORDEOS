import 'dart:math';

import 'package:cordis/services/tokenization/build_service.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';

/// Service responsible for calculating token positions and applying them to widgets.
///
/// Handles the complex positioning logic for chords and lyrics, including:
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
  TokenPositionMap calculateTokenPositions(
    OrganizedTokens contentTokens,
    PositioningContext ctx,
    Map<ContentToken, Measurements> tokenMeasurements, {
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
  }) {
    Measurements chordMsr = _builder.measureText(
      text: 'teste',
      style: chordStyle,
    );
    Measurements lyricMsr = _builder.measureText(
      text: 'teste',
      style: lyricStyle,
    );

    if (ctx.isEditMode) {
      chordMsr.height += TokenizationConstants.chordTokenHeightPadding;
    }

    final precedingOffset = _calculatePrecedingChordOffset(
      contentTokens,
      tokenMeasurements,
      ctx,
    );

    final lineHeight = chordMsr.height + lyricMsr.size + ctx.chordLyricSpacing;

    double yOffset = chordMsr.height;
    final positionMap = TokenPositionMap();
    for (var line in contentTokens.lines) {
      double chordX = 0;
      double lyricsX = 0;

      for (var word in line.words) {
        bool lineBroke = false;
        List<({ContentToken token, double x, double y, TokenType type})>
        wordPositions = [];
        for (var token in word.tokens) {
          final msr = tokenMeasurements[token];
          if (msr == null) continue;

          switch (token.type) {
            case TokenType.chord:
              if (lyricsX < chordX) {
                /// Add underline token to push lyrics below chord
                /// Only add if chord is ahead of lyrics, otherwise lyrics will be positioned correctly below chord
                if (wordPositions.isNotEmpty) {
                  wordPositions.add((
                    token: ContentToken(text: '', type: TokenType.underline),
                    x: lyricsX,
                    y: yOffset,
                    type: TokenType.underline,
                  ));
                }

                lyricsX = chordX;
              }

              wordPositions.add((
                token: token,
                x: lyricsX,
                y: yOffset - lyricMsr.baseline,
                type: TokenType.chord,
              ));

              chordX = lyricsX + msr.width + ctx.minChordSpacing;

              if (chordX > ctx.maxWidth) {
                lineBroke = true;
              }
              break;

            case TokenType.lyric:
              double xOffset = max(precedingOffset, lyricsX);

              wordPositions.add((
                token: token,
                x: xOffset,
                y: yOffset,
                type: TokenType.lyric,
              ));

              lyricsX = xOffset + msr.width + ctx.letterSpacing;

              if (lyricsX > ctx.maxWidth) {
                lineBroke = true;
              }
              break;

            case TokenType.space:
              if (msr.width + lyricsX > ctx.maxWidth) {
                lineBroke = true;
                break;
              }

              wordPositions.add((
                token: token,
                x: lyricsX,
                y: yOffset,
                type: TokenType.space,
              ));
              lyricsX += msr.width + ctx.letterSpacing;
              break;

            case TokenType.precedingChordTarget:
              wordPositions.add((
                token: token,
                x: 0,
                y: yOffset,
                type: TokenType.precedingChordTarget,
              ));
              lyricsX = precedingOffset;
              break;
            case TokenType.underline:
            // There shouldnt be a case where we need to position an underline
            // During the initial layout calculation,
            // Since they are only added when a chord is cramped.
            case TokenType.newline:
              break;
          }
        }

        if (lineBroke) {
          // Reposition word to new line
          yOffset += lineHeight + ctx.lineBreakSpacing;

          lyricsX = precedingOffset;
          chordX = precedingOffset;
          for (var pos in wordPositions) {
            switch (pos.type) {
              case TokenType.chord:
                positionMap.setPosition(
                  pos.token,
                  lyricsX,
                  yOffset - lyricMsr.baseline,
                );
                chordX =
                    lyricsX +
                    tokenMeasurements[pos.token]!.width +
                    ctx.minChordSpacing;
                break;
              case TokenType.lyric:
                positionMap.setPosition(pos.token, lyricsX, yOffset);
                lyricsX +=
                    tokenMeasurements[pos.token]!.width + ctx.letterSpacing;
                break;
              case TokenType.underline:
                positionMap.setPosition(pos.token, lyricsX, yOffset);
                lyricsX +=
                    tokenMeasurements[pos.token]!.width + ctx.letterSpacing;
                break;
              case TokenType.precedingChordTarget:
              case TokenType.space:
              case TokenType.newline:
                debugPrint("Invalid Token Found after linebreak");
                break;
            }
          }
        } else {
          // Record positions normally
          for (var pos in wordPositions) {
            positionMap.setPosition(pos.token, pos.x, pos.y);
          }
        }
      }

      yOffset += lineHeight + ctx.lineSpacing;
    }

    return positionMap;
  }

  /// Applies pre-calculated positions to widgets, creating Positioned widgets.
  ///
  /// Uses the TokenPositionMap to position widgets without recalculating layout.
  /// Handles line breaking and oversized words using position information.
  ContentTokenized applyPositionsToWidgets(
    OrganizedWidgets contentWidgets,
    TokenPositionMap positionMap,
    PositioningContext ctx, {
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
  }) {
    Measurements chordMsr = _builder.measureText(
      text: 'teste',
      style: chordStyle,
    );

    if (ctx.isEditMode) {
      chordMsr.height += TokenizationConstants.chordTokenHeightPadding;
    }

    final tokenWidgets = <Positioned>[];
    double maxY = chordMsr.height;

    // Iterate through widgets and tokens together to get both widget and position
    for (var widgetLine in contentWidgets.lines) {
      for (var widgetWord in widgetLine.words) {
        for (var msrWidget in widgetWord.widgets) {
          // Skip newlines and underlines
          if (msrWidget.type == TokenType.newline ||
              msrWidget.type == TokenType.underline) {
            continue;
          }

          // Get position from map
          final x = positionMap.getX(msrWidget.token) ?? 0.0;
          final y = positionMap.getY(msrWidget.token) ?? 0.0;

          tokenWidgets.add(
            Positioned(
              left: x,
              top: y,
              width: msrWidget.measurements.width,
              child: msrWidget.widget,
            ),
          );

          // Track max Y for total height
          maxY = max(maxY, y + msrWidget.measurements.height);
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
      double linePrecedingOffset = 0;
      bool hasSpaceBeforeLyrics = false;
      bool hasSkippedAddingSpace = false;
      bool foundLyric = false;
      for (var word in line.words) {
        if (foundLyric) {
          break;
        }
        for (var token in word.tokens) {
          if (token.type == TokenType.lyric) {
            foundLyric = true;
            break;
          } else if (token.type == TokenType.space) {
            // Accumulate space width before saving
            // -1 due to preceding indicator
            if (hasSkippedAddingSpace) {
              linePrecedingOffset += tokenMeasurements[token]?.width ?? 0.0;
            } else {
              hasSkippedAddingSpace = true;
            }
            hasSpaceBeforeLyrics = true;
            continue;
          } else {
            // Accumulate all chord widths
            linePrecedingOffset += tokenMeasurements[token]?.width ?? 0.0;
          }
        }
      }
      if (linePrecedingOffset > precedingOffset && hasSpaceBeforeLyrics) {
        precedingOffset = linePrecedingOffset;
      }
    }

    if (precedingOffset != 0) {
      precedingOffset += ctx.minChordSpacing;
    }
    return precedingOffset;
  }
}
