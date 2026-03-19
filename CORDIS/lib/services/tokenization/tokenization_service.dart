import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:cordis/services/tokenization/build_service.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:cordis/services/tokenization/position_service.dart';
import 'package:flutter/material.dart';

/// Service responsible for tokenizing ChordPro content,
/// organizing it into a hierarchical structure,
/// and orchestrating the widget building and positioning workflow.
class TokenizationService {
  const TokenizationService();

  static const _builder = TokenizationBuilder();
  static const _positioner = PositionService();

  /// Tokenizes the given content string into a list of ContentTokens.
  ///
  /// Parses ChordPro-style content with chords in brackets [Am], [F#m7],.
  /// Creates preceding chord target tokens in lines where there are no spaces before lyrics,
  /// allowing chords to be positioned before the first lyric character.
  ///
  /// Example:
  /// ```dart
  /// final service = TokenizationService();
  /// final tokens = service.tokenize('[Am]Amazing [F]grace\nHow [C]sweet');
  /// ```
  List<ContentToken> tokenize(String content) {
    if (content.isEmpty) {
      return [];
    }

    final List<ContentToken> tokens = [];
    final List<ContentToken> lineTokens = [];
    bool foundLyricInLine = false;
    for (int index = 0; index < content.length; index++) {
      final char = content[index];
      if (char == '\n') {
        if (lineTokens.isEmpty) {
          // Handle empty lines
          tokens.add(ContentToken(type: TokenType.newline, text: char));
          continue;
        }

        lineTokens.add(ContentToken(type: TokenType.newline, text: char));

        // Add Line and Reset for the next line
        foundLyricInLine = false;
        tokens.addAll(lineTokens);
        lineTokens.clear();
      } else if (char == ' ' || char == '\t') {
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
      } else if (char == '[') {
        index++; // Move past the '['
        String chordText = '';
        while (index < content.length && content[index] != ']') {
          chordText += content[index];
          index++;
        }
        lineTokens.add(ContentToken(type: TokenType.chord, text: chordText));
      } else {
        if (!foundLyricInLine) {
          foundLyricInLine = true;
          // Go backwards,
          // If no space found before this lyric, add a preceding chord target token
          // If there are spaces, add a separatorToken to indicate the boundary between lyric start and preceding chords / target
          if (lineTokens.isEmpty) {
            lineTokens.add(ContentToken(type: TokenType.precedingChordTarget));
            lineTokens.add(ContentToken(type: TokenType.separator));
          } else {
            for (int j = lineTokens.length - 1; j >= 0; j--) {
              if (lineTokens[j].type == TokenType.space) {
                lineTokens.insert(
                  j + 1,
                  ContentToken(type: TokenType.separator),
                );
                break;
              }
              if (j == 0) {
                lineTokens.insert(0, ContentToken(type: TokenType.separator));
                lineTokens.insert(
                  0,
                  ContentToken(type: TokenType.precedingChordTarget),
                );
              }
              if (lineTokens[j].type == TokenType.newline) {
                lineTokens.insert(
                  j + 1,
                  ContentToken(type: TokenType.separator),
                );
                lineTokens.insert(
                  j + 1,
                  ContentToken(type: TokenType.precedingChordTarget),
                );
                break;
              }
            }
          }
        }
        lineTokens.add(ContentToken(type: TokenType.lyric, text: char));
      }
    }

    if (lineTokens.isNotEmpty) {
      tokens.addAll(lineTokens);
    }

    if (tokens.isNotEmpty && tokens.last.type == TokenType.newline) {
      tokens.removeLast();
    }

    return tokens;
  }

  /// Reconstructs the content string from a list of ContentTokens.
  ///
  /// Converts tokens back to ChordPro format with chords in brackets.
  /// Purely visual tokens (precedingChordTarget, underline) are excluded.
  String reconstructContent(List<ContentToken> tokens) {
    return tokens.map((token) {
      switch (token.type) {
        case TokenType.chord:
          return '[${token.text}]';
        case TokenType.lyric:
        case TokenType.space:
        case TokenType.newline:
          return token.text;
        case TokenType.precedingChordTarget:
        case TokenType.separator:
        case TokenType.underline:
          return ''; // Purely visual tokens - return empty string
      }
    }).join();
  }

  /// Creates tokenized and positioned content for both edit and view modes.
  ///
  /// **Edit Mode** (provide [content] and [buildCtx])
  /// **View Mode** (provide [content] and [contentFilters])
  /// Orchestrates the complete content creation workflow from a content string:
  /// 1. Tokenizes content into ChordPro format
  /// 2. Mode processing (Chord transposition // Filter Application)
  /// 3. Organizes tokens into hierarchical structure
  /// 4. Measures tokens
  /// 5. Calculates positions
  /// 6. Builds widgets (Edit // view)
  /// 7. Positions widgets for final rendering
  ///
  /// Returns [ContentTokenized] with positioned widgets and total content height.
  ContentTokenized createContent({
    required String content,
    required PositioningContext posCtx,
    required TokenBuildContext buildCtx,
    List<ContentToken>? initialTokens,
    // View mode parameters
    Map<ContentFilter, bool>? contentFilters,
  }) {
    // Step 1: Tokenize content (shared)
    List<ContentToken> tokens = initialTokens ?? tokenize(content);

    // Underline tokens are transient layout artifacts.
    // Ensure they never persist across rebuilds when using cached initialTokens.
    tokens = tokens
        .where((token) => token.type != TokenType.underline)
        .toList();

    // Step 2: Apply mode-specific processing
    if (posCtx.isEditMode) {
    } else {
      tokens = filterTokens(tokens, contentFilters!);
    }

    // Step 3: Organize tokens
    final organizedTokens = _organize(tokens);

    // Step 4: Measure tokens
    final tokenMeasurements = <ContentToken, Measurements>{};
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.chord:
          tokenMeasurements[token] = _builder.measureText(
            text: buildCtx.transposeChord(token.text),
            style: buildCtx.chordStyle,
            cache: buildCtx.cache,
          );
          if (posCtx.isEditMode && token.type == TokenType.chord) {
            tokenMeasurements[token]!.size +=
                2 *
                TokenizationConstants
                    .chordTokenHeightPadding; // Top + bottom visual padding
            tokenMeasurements[token]!.width +=
                TokenizationConstants
                    .chordTokenWidthPadding;          }
          break;

        case TokenType.space:
        case TokenType.lyric:
          tokenMeasurements[token] = _builder.measureText(
            text: token.text,
            style: buildCtx.lyricStyle,
            cache: buildCtx.cache,
          );
          break;
        case TokenType.precedingChordTarget:
        case TokenType.separator:
          final msr = _builder.measureText(
            text: 'Test',
            style: buildCtx.lyricStyle,
            cache: buildCtx.cache,
          );
          tokenMeasurements[token] = Measurements(
            width: TokenizationConstants.precedingTargetWidth,
            height: msr.height,
            baseline: msr.baseline,
            size: msr.size,
          );
          break;
        case TokenType.underline:
        case TokenType.newline:
          // These tokens are dynamic, the measurements are based on positioning.
          break;
      }
    }

    // Step 5: Calculate positions for all tokens
    final tokenPositions = _positioner.calculateTokenPositions(
      organizedTokens: organizedTokens,
      posCtx: posCtx,
      buildCtx: buildCtx,
      tokenMsr: tokenMeasurements,
    );

    // Step 6: Build widgets
    final OrganizedWidgets contentWidgets;
    if (posCtx.isEditMode) {
      // Build edit widgets with pre-calculated positions
      contentWidgets = _builder.buildEditWidgets(
        contentTokens: organizedTokens,
        tokenMeasurements: tokenMeasurements,
        tokens: tokens,
        ctx: buildCtx,
        tokenPositions: tokenPositions,
      );
    } else {
      // Build view widgets
      contentWidgets = _builder.buildViewWidgets(
        organizedTokens: organizedTokens,
        tokenMeasurements: tokenMeasurements,
        tokens: tokens,
        ctx: buildCtx,
        tokenPositions: tokenPositions,
      );
    }

    // Step 7: Apply positions to widgets (shared)
    final positionedContent = _positioner.applyPositionsToWidgets(
      contentWidgets,
      tokenMeasurements,
      tokenPositions,
      posCtx,
      buildCtx,
    );

    return positionedContent;
  }

  /// Filters tokens based on content filter settings.
  ///
  /// Allows showing/hiding chords and lyrics independently.
  /// Visual tokens (newline, underline, precedingChordTarget) are shown if any content is visible.
  List<ContentToken> filterTokens(
    List<ContentToken> tokens,
    Map<ContentFilter, bool> contentFilters,
  ) {
    return tokens.where((token) {
      switch (token.type) {
        case TokenType.chord:
          return contentFilters[ContentFilter.chords]!;
        case TokenType.space:
        case TokenType.lyric:
          return contentFilters[ContentFilter.lyrics]!;
        case TokenType.precedingChordTarget:
          return false;
        case TokenType.underline:
          debugPrint("UNDERLINE FOUND ON FILTERING");
          return false;
        case TokenType.separator:
        case TokenType.newline:
          // Returns true if any content is shown
          return contentFilters[ContentFilter.chords]! ||
              contentFilters[ContentFilter.lyrics]!;
      }
    }).toList();
  }

  /// Organizes tokens into a hierarchical structure: lines -> words -> tokens.
  ///
  /// Logic:
  /// - Newline tokens end the current line
  /// - Space tokens end the current word
  /// - Lyric, chord, and precedingChordTarget tokens are part of words
  ///
  /// Returns [OrganizedTokens] with clear hierarchical structure.
  OrganizedTokens _organize(List<ContentToken> tokens) {
    // Organize tokens by lines and words
    final currentWord = <ContentToken>[];
    final currentLine = <TokenWord>[];
    final lines = <TokenLine>[];
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.newline:
          // End of line
          if (currentWord.isNotEmpty) {
            currentLine.add(TokenWord(List.from(currentWord)));
            currentWord.clear();
          }

          // Add newline as separate word
          currentLine.add(TokenWord([token]));

          // Add line to content
          lines.add(TokenLine(List.from(currentLine)));
          currentLine.clear();
          break;

        case TokenType.separator:
        case TokenType.space:
          // End of word
          if (currentWord.isNotEmpty) {
            currentLine.add(TokenWord(List.from(currentWord)));
            currentWord.clear();
          }

          // Add space as separate word
          currentLine.add(TokenWord([token]));
          break;

        case TokenType.lyric:
        case TokenType.chord:
        case TokenType.precedingChordTarget:
        case TokenType.underline:
          // Part of a word
          currentWord.add(token);
          break;
      }
    }
    // Add any remaining tokens
    if (currentWord.isNotEmpty) {
      currentLine.add(TokenWord(currentWord));
    }
    if (currentLine.isNotEmpty) {
      lines.add(TokenLine(currentLine));
    }
    return OrganizedTokens(lines);
  }
}
