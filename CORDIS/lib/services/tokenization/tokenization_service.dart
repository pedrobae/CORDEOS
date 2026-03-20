import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:cordis/services/tokenization/build_service.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:cordis/services/tokenization/position_service.dart';

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
    for (int index = 0; index < content.length; index++) {
      final char = content[index];
      if (char == '\n') {
        if (lineTokens.isEmpty) {
          // Trim empty lines
          continue;
        }

        _ensureSeparators(lineTokens);

        lineTokens.add(ContentToken(type: TokenType.newline, text: char));

        tokens.addAll(lineTokens);
        lineTokens.clear();
      } else if (char == ' ' || char == '\t') {
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
      } else if (char == '[') {
        // GROUP CHORD TOKEN
        index++;
        String chordText = '';
        while (index < content.length && content[index] != ']') {
          chordText += content[index];
          index++;
        }
        lineTokens.add(ContentToken(type: TokenType.chord, text: chordText));
      } else if (char == '<') {
        lineTokens.add(ContentToken(type: TokenType.preSeparator, text: char));
      } else if (char == '>') {
        lineTokens.add(ContentToken(type: TokenType.postSeparator, text: char));
      } else {
        lineTokens.add(ContentToken(type: TokenType.lyric, text: char));
      }
    }

    if (lineTokens.isNotEmpty) {
      _ensureSeparators(lineTokens);
      tokens.addAll(lineTokens);
    }

    if (tokens.isNotEmpty && tokens.last.type == TokenType.newline) {
      tokens.removeLast();
    }

    return tokens;
  }

  void _ensureSeparators(List<ContentToken> lineTokens) {
    final hasPreSeparator = lineTokens.any(
      (token) => token.type == TokenType.preSeparator,
    );
    final hasPostSeparator = lineTokens.any(
      (token) => token.type == TokenType.postSeparator,
    );

    if (!hasPreSeparator) {
      // If there are no pre-separators, find the first lyric token and insert a target before it.
      // If there are no lyric tokens, position at the end of the line.
      final firstLyricsIndex = lineTokens.indexWhere(
        (token) => token.type == TokenType.lyric,
      );
      final insertIndex = firstLyricsIndex != -1
          ? firstLyricsIndex
          : lineTokens.length;
      lineTokens.insert(
        insertIndex,
        ContentToken(type: TokenType.preSeparator, text: '<'),
      );
    }
    if (!hasPostSeparator) {
      // If there are no post-separators, find the first lyric token and insert a target after it.
      // If there are no lyric tokens, position at the end of the line.
      int lastLyricIndex = -1;
      for (int i = lineTokens.length - 1; i >= 0; i--) {
        if (lineTokens[i].type == TokenType.lyric) {
          lastLyricIndex = i;
          break;
        }
      }
      final insertIndex = lastLyricIndex != -1
          ? lastLyricIndex
          : lineTokens.length - 1;
      lineTokens.insert(
        insertIndex + 1,
        ContentToken(type: TokenType.postSeparator, text: '>'),
      );
    }
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
        case TokenType.preSeparator:
          return '<';
        case TokenType.postSeparator:
          return '>';
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

    // // Assert that all tokens and organization maintain the same order and count after processing
    // assert(() {
    //   final flatOrganizedTokens = organizedTokens.lines
    //       .expand((line) => line.words)
    //       .expand((word) => word.tokens)
    //       .toList();
    //   for (int i = 0; i < tokens.length; i++) {
    //     if (tokens[i] != flatOrganizedTokens[i]) {
    //       throw Exception(
    //         'Token mismatch at index $i after organization. Token: ${tokens[i].text} (${tokens[i].type}), Organized: ${flatOrganizedTokens[i].text} (${flatOrganizedTokens[i].type})',
    //       );
    //     }
    //   }
    //   return true;
    // }());

    // Step 4: Measure tokens
    final tokenMeasurements = <ContentToken, Measurements>{};
    for (var token in tokens) {
      switch (token.type) {
        case TokenType.chord:
          tokenMeasurements[token] = _builder.measureText(
            text: buildCtx.transposeChord(token.text),
            style: buildCtx.chordStyle,
            cache: buildCtx.cache,
            isChordToken: posCtx.isEditMode
          );
          break;

        case TokenType.space:
        case TokenType.lyric:
          tokenMeasurements[token] = _builder.measureText(
            text: token.text,
            style: buildCtx.lyricStyle,
            cache: buildCtx.cache,
          );
          break;
        case TokenType.preSeparator:
        case TokenType.postSeparator:
          final msr = _builder.measureText(
            text: '<>',
            style: buildCtx.lyricStyle,
            cache: buildCtx.cache,
          );
          final chordMsr = _builder.measureText(
            text: buildCtx.transposeChord(token.text),
            style: buildCtx.chordStyle,
            cache: buildCtx.cache,
            isChordToken: posCtx.isEditMode
          );
          tokenMeasurements[token] = Measurements(
            width: TokenizationConstants.targetWidth,
            height: msr.height + chordMsr.height + posCtx.chordLyricSpacing,
            baseline: msr.baseline,
            size: msr.size + chordMsr.size
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

    // Assert that all lines start at x=0
    // assert(() {
    //   for (var line in organizedTokens.lines) {
    //     final firstToken = line.words.expand((word) => word.tokens).first;
    //     final firstTokenX = tokenPositions.getX(firstToken)!;
    //     if (firstTokenX != 0) {
    //       throw Exception(
    //         'Line does not start at x=0. First token: ${firstToken.text} (${firstToken.type}), x: $firstTokenX',
    //       );
    //     }
    //   }
    //   return true;
    // }());

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
        case TokenType.postSeparator:
        case TokenType.preSeparator:
        case TokenType.underline:
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
          currentWord.add(token);
          currentLine.add(TokenWord(List.from(currentWord)));
          lines.add(TokenLine(List.from(currentLine)));

          currentLine.clear();
          currentWord.clear();
          break;
        case TokenType.space:
          if (currentWord.isNotEmpty) {
            currentLine.add(TokenWord(List.from(currentWord)));
            currentWord.clear();
          }
          currentLine.add(TokenWord([token]));
          break;
        case TokenType.lyric:
        case TokenType.chord:
          currentWord.add(token);
          break;
        case TokenType.preSeparator:
        case TokenType.postSeparator:
          if (currentWord.isNotEmpty) {
            currentLine.add(TokenWord(List.from(currentWord)));
            currentWord.clear();
          }
          currentLine.add(TokenWord([token]));
          break;
        case TokenType.underline:
          throw Exception(
            'Underline tokens should not be present during organization',
          );
      }
    }
    if (currentWord.isNotEmpty) {
      currentLine.add(TokenWord(List.from(currentWord)));
    }
    if (currentLine.isNotEmpty) {
      lines.add(TokenLine(List.from(currentLine)));
    }
    return OrganizedTokens(lines);
  }
}
