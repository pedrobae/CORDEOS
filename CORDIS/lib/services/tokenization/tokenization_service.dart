import 'package:cordis/providers/layout_settings_provider.dart';
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
    bool spaceBeforeLyrics = false;
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

        if (!spaceBeforeLyrics) {
          // Insert preceding chord target tokens at the starts of lines
          lineTokens.insert(
            0,
            ContentToken(type: TokenType.precedingChordTarget, text: ''),
          );
        }

        // Add Line and Reset for the next line
        spaceBeforeLyrics = false;
        foundLyricInLine = false;
        tokens.addAll(lineTokens);
        lineTokens.clear();
      } else if (char == ' ' || char == '\t') {
        if (!foundLyricInLine) {
          spaceBeforeLyrics = true;
        }
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
        foundLyricInLine = true;
        lineTokens.add(ContentToken(type: TokenType.lyric, text: char));
      }
    }

    if (lineTokens.isNotEmpty) {
      if (!spaceBeforeLyrics) {
        // Insert preceding chord target tokens at the starts of lines
        lineTokens.insert(
          0,
          ContentToken(type: TokenType.precedingChordTarget, text: ''),
        );
      }
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
    required String Function(String) transposeChord,
    List<ContentToken>? initialTokens,
    // View mode parameters
    Map<ContentFilter, bool>? contentFilters,
  }) {
    final isEditMode = contentFilters == null;

    // Step 1: Tokenize content (shared)
    final tokens = initialTokens ?? tokenize(content);

    // Step 2: Apply mode-specific processing
    for (var token in tokens) {
      if (token.type == TokenType.chord) {
        token.text = transposeChord(token.text);
      }
    }

    if (!isEditMode) {
      filterTokens(tokens, contentFilters);
    }

    // Step 3: Organize tokens
    final organizedTokens = _organize(tokens);

    // Step 4: Measure tokens and calculate positions
    final tokenMeasurements = <ContentToken, Measurements>{};
    for (var token in tokens) {
      if (token.type != TokenType.newline &&
          token.type != TokenType.underline) {
        final style = token.type == TokenType.chord
            ? buildCtx.chordStyle
            : buildCtx.lyricStyle;
        final cache = isEditMode ? buildCtx.cache : null;
        final measured = _builder.measureText(
          text: token.text,
          style: style,
          cache: cache,
        );

        // Clone measurements per token to avoid mutating shared cached instances.
        tokenMeasurements[token] = Measurements(
          width: measured.width,
          height: measured.height,
          baseline: measured.baseline,
          size: measured.size,
        );

        if (isEditMode && token.type == TokenType.chord) {
          tokenMeasurements[token]!.height += TokenizationConstants
              .chordTokenHeightPadding; // Top + bottom visual padding
          tokenMeasurements[token]!.width += TokenizationConstants
              .chordTokenWidthPadding; // Left + right visual padding
        }
      }
    }

    // Step 5: Calculate positions for all tokens
    final tokenPositions = _positioner.calculateTokenPositions(
      organizedTokens: organizedTokens,
      posCtx: posCtx,
      buildCtx: buildCtx,
      tokenMsr: tokenMeasurements,
    );

    // Step 6: Build widgets (mode-specific)
    final OrganizedWidgets contentWidgets;
    if (isEditMode) {
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
          debugPrint("UNDERLINE FOUND ON FILTER");
          return false;
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
          // Part of a word
          currentWord.add(token);
        case TokenType.underline:
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
