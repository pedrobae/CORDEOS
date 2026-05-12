import 'package:cordeos/services/tokenization/helper_classes.dart';

/// Service responsible for tokenizing ChordPro content,
/// organizing it into a hierarchical structure,
/// and orchestrating the widget building and positioning workflow.
class TokenizationService {
  const TokenizationService();

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
  List<ContentToken> tokenize(
    String content, {
    required bool showLyrics,
    required bool showChords,
    required String Function(String) transposeChord,
  }) {
    if (content.isEmpty) {
      return [];
    }

    final List<ContentToken> tokens = [];
    final List<ContentToken> lineTokens = [];
    for (int index = 0; index < content.length; index++) {
      final char = content[index];
      if (char == '\n' && (showLyrics || showChords)) {
        if (lineTokens.isEmpty) {
          // Trim empty lines
          continue;
        }

        _ensureSeparators(lineTokens);
        _preHandling(lineTokens);
        _postHandling(lineTokens);

        lineTokens.add(ContentToken(type: TokenType.newline, text: char));

        tokens.addAll(lineTokens);
        lineTokens.clear();
      } else if (char == ' ' && showLyrics) {
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
      } else if (char == '\t' && showLyrics) {
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
        lineTokens.add(ContentToken(type: TokenType.space, text: char));
      } else if (char == '[') {
        // GROUP CHORD TOKEN
        index++;
        String chordText = '';
        while (index < content.length && content[index] != ']') {
          chordText += content[index];
          index++;
        }
        if (showChords) {
          lineTokens.add(
            ContentToken(
              type: TokenType.chord,
              text: transposeChord(chordText),
            ),
          );
        }
      } else if (char == '<' && (showLyrics || showChords)) {
        lineTokens.add(ContentToken(type: TokenType.preSeparator, text: char));
      } else if (char == '>' && (showLyrics || showChords)) {
        lineTokens.add(ContentToken(type: TokenType.postSeparator, text: char));
      } else if (char == '@' && (showLyrics || showChords)) {
        lineTokens.add(
          ContentToken(type: TokenType.preChordTarget, text: char),
        );
      } else if (char == '&' && (showLyrics || showChords)) {
        lineTokens.add(
          ContentToken(type: TokenType.postChordTarget, text: char),
        );
      } else if (showLyrics) {
        lineTokens.add(ContentToken(type: TokenType.lyric, text: char));
      }
    }

    if (lineTokens.isNotEmpty) {
      _ensureSeparators(lineTokens);
      _preHandling(lineTokens);
      _postHandling(lineTokens);
      tokens.addAll(lineTokens);
    }

    if (tokens.isNotEmpty && tokens.last.type == TokenType.newline) {
      tokens.removeLast();
    }

    return tokens;
  }

  /// Mutates the line tokens to ensure that chord targets are positioned before chords
  void _preHandling(List<ContentToken> lineTokens) {
    final iteratingLine = List<ContentToken>.from(lineTokens);
    int offset = 0; // Track the offset caused by insertions
    for (int i = 0; i < iteratingLine.length; i++) {
      final token = iteratingLine[i];
      if (token.type == TokenType.preSeparator) {
        break;
      } else if (token.type == TokenType.chord) {
        lineTokens.insert(
          i + offset,
          ContentToken(type: TokenType.preChordTarget, text: token.text),
        );
        offset++; // Increment the offset for each insertion
      }
    }
  }

  /// Mutates the line tokens to ensure that chord targets are positioned before chords
  void _postHandling(List<ContentToken> lineTokens) {
    final iteratingLine = List<ContentToken>.from(lineTokens);
    int offset = 0; // Track the offset caused by removals
    for (
      int i = iteratingLine.indexWhere(
        (token) => token.type == TokenType.postSeparator,
      );
      i < iteratingLine.length;
      i++
    ) {
      final token = iteratingLine[i];
      if (token.type == TokenType.chord) {
        lineTokens.insert(
          i + offset,
          ContentToken(type: TokenType.postChordTarget, text: token.text),
        );
        offset++; // Increment the offset for each insertion
      }
      if (token.type == TokenType.space) {
        lineTokens.removeAt(i + offset);
        offset--; // Decrement the offset for each removal
      }
    }
  }

  void _ensureSeparators(List<ContentToken> lineTokens) {
    final hasPreSeparator = lineTokens.any(
      (token) => token.type == TokenType.preSeparator,
    );
    final hasPostSeparator = lineTokens.any(
      (token) => token.type == TokenType.postSeparator,
    );

    if (!hasPreSeparator) {
      final firstLyricIndex = lineTokens.indexWhere(
        (token) => token.type == TokenType.lyric,
      );

      if (firstLyricIndex != -1) {
        // Has lyrics, search preceding space
        final precedingSpaceIndex = lineTokens
            .sublist(0, firstLyricIndex)
            .indexWhere((token) => token.type == TokenType.space);

        if (precedingSpaceIndex != -1) {
          // Has Preceding Space, swap preceding space for preSeparator
          lineTokens.removeAt(precedingSpaceIndex);
          lineTokens.insert(
            precedingSpaceIndex,
            ContentToken(type: TokenType.preSeparator, text: '<'),
          );
        } else {
          // Has no preceding space, search preceding chord
          final precedingChordIndex =
              lineTokens.sublist(0, firstLyricIndex).length -
              1 -
              lineTokens
                  .sublist(0, firstLyricIndex)
                  .reversed
                  .toList()
                  .indexWhere((token) => token.type == TokenType.space);

          if (precedingChordIndex != -1) {
            // Has Preceding Chord, place separator before chord
            lineTokens.insert(
              precedingChordIndex,
              ContentToken(type: TokenType.preSeparator, text: '<'),
            );
          } else {
            // Place separator at start
            lineTokens.insert(
              0,
              ContentToken(type: TokenType.preSeparator, text: '<'),
            );
          }
        }
      }
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
          return ' ';
        case TokenType.preChordTarget:
        case TokenType.postSeparator:
        case TokenType.underline:
        case TokenType.postChordTarget:
          return ''; // Purely visual tokens - return empty string
      }
    }).join();
  }

  /// Organizes tokens into a hierarchical structure: lines -> words -> tokens.
  ///
  /// Logic:
  /// - Newline tokens end the current line
  /// - Space tokens end the current word
  /// - Lyric, chord, and precedingChordTarget tokens are part of words
  ///
  /// Returns [OrganizedTokens] with clear hierarchical structure.
  OrganizedTokens organize(List<ContentToken> tokens) {
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
        case TokenType.preChordTarget:
        case TokenType.postChordTarget:
          if (currentWord.isNotEmpty) {
            currentLine.add(TokenWord(List.from(currentWord)));
            currentWord.clear();
          }
          currentLine.add(TokenWord([token]));
          break;
        case TokenType.underline:
          throw Exception(
            'These tokens should not be present during organization',
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
