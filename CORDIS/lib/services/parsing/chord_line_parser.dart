import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:cordis/models/dtos/pdf_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/utils/color.dart';
import 'package:flutter/material.dart';

class ChordLineParser {
  static const String _chordPattern =
      r'\b[A-G](?:#|b)?' // Chord Root (C, D, E, F, G, A, B)(# or b)
      r'(?:m|maj|min|sus|aug|dim)?' // Optional quality (minor, major, sus, etc)
      r'(?:\d{1,2}|maj7|M7|m7|min7|sus2|sus4|add\d{1,2})?' // Optional extension
      r'(?:M|maj)?' // Optional trailing major
      r'(?:\/[A-G](?:#|b)?)?' // Optional slash chord
      r'\b';

  /// Parses sections from the given [ImportVariant] and creates the parsed objects.
  void parseBySimpleText(ParsingResult result) {
    // Iterates through each section of the cipher creating Section objects
    Map<String, SectionDto> parsedSections = result.parsedSections;
    List<String> songStructure = result.songStructure;
    int incrementalDefaultCode = 0;

    List<RawSection> rawSections = result.rawSections;

    for (var rawSection in rawSections) {
      String? code = rawSection.code;
      if (code == null) {
        // Assign a default code if none is found
        code = incrementalDefaultCode.toString();
        incrementalDefaultCode++;
      }

      // If the section is marked as duplicate, skip creating a new Section object
      if (rawSection.duplicateOf != null) {
        // Add the code of the original section to the song structure
        songStructure.add(rawSection.duplicateOf!);
        // Skip to the next section
        continue;
      }

      // Keep track of song structure
      songStructure.add(code);
      rawSection.code = code;

      // Build the Section object
      final parsedSection = SectionDto(
        color: colorToHex(rawSection.color ?? Colors.grey),
        contentCode: code,
        contentType: rawSection.suggestedLabel,
        contentText: _buildContentFromSimpleText(rawSection.content),
      );

      parsedSections[code] = parsedSection;
    }
  }

  void parseByPdfFormatting(ParsingResult result) {
    // Iterates through each section of the variant creating Section objects
    Map<String, SectionDto> parsedSections = result.parsedSections;
    List<RawSection> rawSections = result.rawSections;
    List<String> songStructure = result.songStructure;
    int incrementalDefaultCode = 1;

    for (var rawSection in rawSections) {
      String? code = rawSection.code;
      if (code == null || code.isEmpty) {
        // Assign a default code if none is found
        code = incrementalDefaultCode.toString();
        incrementalDefaultCode++;
      }

      // If the section is marked as duplicate, skip creating a new Section object
      if (rawSection.duplicateOf != null) {
        // Add the code of the original section to the song structure
        songStructure.add(rawSection.duplicateOf!);
        rawSection.code = code;
        // Skip to the next section
        continue;
      }

      // Keep track of song structure
      songStructure.add(code);
      rawSection.code = code;

      // Build the Section object
      final parsedSection = SectionDto(
        color: colorToHex(rawSection.color ?? Colors.grey),
        contentCode: code,
        contentType: rawSection.suggestedLabel,
        contentText: _buildContentFromLinesData(
          rawSection.linesData as List<LineData>,
        ),
      );

      parsedSections[code] = parsedSection;
    }
  }

  String _buildContentFromLinesData(List<LineData> lines) {
    /// Use bouds from each word to position chords over lyrics in ChordPro format
    String content = '';
    for (int index = 0; index < lines.length - 1; index++) {
      LineData lineData = lines[index];
      String lineText = lineData.text;

      LineData? nextLineData = lines[index + 1];
      String nextLineText = nextLineData.text;

      if (_isChordLine(lineText)) {
        if (!_isChordLine(nextLineText)) {
          // This line is a chord line followed by a lyric line
          // Merge chords with the next line, associating chord positions
          String chordProLine = _mergeByPdfFormatting(lineData, nextLineData);
          content = '$content$chordProLine\n';
        } else if (_isChordLine(nextLineText)) {
          // This line is a chord line followed by another chord line
          // Format as chord-only line
          content = '$content${_formatChordOnlyLine(lineText)}\n';
        }
      } else if (!_isChordLine(lineText)) {
        // This line is a lyric line
        // Lyric lines are handled by previous line (except if it is the first line)
        if (!_isChordLine(nextLineText)) {
          // This line is a lyric line followed by another lyric line
          // If it's the first line, add it as-is
          if (index == 0) {
            content = '$content$lineText\n';
          }
          // Add the next line as-is check if it is the last line, for proper newline handling
          if (index + 1 == lines.length - 1) {
            content = '$content$nextLineText';
          } else {
            content = '$content$nextLineText\n';
          }
        }
      }
    }
    // Handle last line if chord line
    LineData lastLineData = lines[lines.length - 1];
    String lastLineText = lastLineData.text;
    if (_isChordLine(lastLineText)) {
      content = '$content${_formatChordOnlyLine(lastLineText)}';
    } else {
      // Check if section is a single lyric line
      if (lines.length == 1) {
        content = '$content$lastLineText';
      }
    }

    return content;
  }

  String _buildContentFromSimpleText(String rawContent) {
    List<String> lines = rawContent.split('\n');

    String content = '';
    // Iterate through lines in the section, creating the content
    for (int index = 0; index < lines.length - 1; index++) {
      final String lineText = lines[index];

      final String nextLineText = lines[index + 1];

      if (_isChordLine(lineText)) {
        if (!_isChordLine(nextLineText)) {
          // This line is a chord line followed by a lyric line
          // Merge chords with the next line, associating chord positions
          String chordProLine = _mergeLines(lineText, nextLineText);
          content = '$content$chordProLine\n';
        } else if (_isChordLine(nextLineText)) {
          // This line is a chord line followed by another chord line
          // Format as chord-only line
          content = '$content${_formatChordOnlyLine(lineText)}\n';
        }
      } else if (!_isChordLine(lineText)) {
        // This line is a lyric line
        // Lyric lines are handled by previous line (except if it is the first line)
        if (!_isChordLine(nextLineText)) {
          // This line is a lyric line followed by another lyric line
          // If it's the first line, add it as-is
          if (index == 0) {
            content = '$content$lineText\n';
          }
          // Add the next line as-is
          content = '$content$nextLineText\n';
        }
      }
    }
    // Check if the last line is a chord line and add it
    final String lastLineText = lines[lines.length - 1];

    if (_isChordLine(lastLineText)) {
      content = '$content${_formatChordOnlyLine(lastLineText)}';
    }

    return content;
  }

  String _mergeLines(String chordLine, String lyricLine) {
    // Merges chord line and lyric line into a single chord pro formatted line
    StringBuffer mergedLine = StringBuffer();
    int lyricIndex = 0;

    for (int i = 0; i < chordLine.length; i++) {
      if (chordLine[i] != ' ') {
        // Found a chord character, insert chord brackets
        mergedLine.write('[');
        while (i < chordLine.length && chordLine[i] != ' ') {
          mergedLine.write(chordLine[i]);
          i++;
        }
        mergedLine.write(']');
      }
      // Add corresponding lyric character if available
      if (lyricIndex < lyricLine.length) {
        while (lyricIndex <= i && lyricIndex < lyricLine.length) {
          mergedLine.write(lyricLine[lyricIndex]);
          lyricIndex++;
        }
      }
    }
    // Append any remaining lyrics
    if (lyricIndex < lyricLine.length) {
      mergedLine.write(lyricLine.substring(lyricIndex));
    }

    return mergedLine.toString();
  }

  String _mergeByPdfFormatting(LineData chordLineData, LineData lyricLineData) {
    // Merges chord line and lyric line into a single chord pro formatted line
    // Using glyph bounds to insert chords into lyrics
    List<WordData> chordGlyphs = chordLineData.wordList!;

    List<GlyphData> lyricGlyphs = lyricLineData.wordList!
        .expand(
          (word) =>
              word.glyphList +
              [
                GlyphData(
                  bounds: Rect.zero,
                  text: ' ',
                  fontSize: 0.0,
                  fontStyle: [],
                  glyphIndex: 0,
                ),
              ],
        )
        .toList();

    String mergedLine = '';

    double lastLyricRightBound = 0.0;
    while (chordGlyphs.isNotEmpty || lyricGlyphs.isNotEmpty) {
      if (chordGlyphs.isEmpty) {
        // No more chord glyphs, append remaining lyric glyphs
        while (lyricGlyphs.isNotEmpty) {
          mergedLine += lyricGlyphs.removeAt(0).text;
        }
        break;
      } else if (lyricGlyphs.isEmpty) {
        // No more lyric glyphs, append remaining chord glyphs
        // Creating space for the bounds difference
        while (chordGlyphs.isNotEmpty) {
          final chordGlyph = chordGlyphs.removeAt(0);

          final spaceCount =
              (chordGlyph.bounds.left - lastLyricRightBound) ~/
              chordGlyph.fontSize!;
          mergedLine += ' ' * spaceCount;
          mergedLine += '[${chordGlyph.text}]';
          lastLyricRightBound =
              lastLyricRightBound + spaceCount * chordGlyph.fontSize!;
        }
        break;
      } else {
        if (chordGlyphs[0].bounds.left <= lyricGlyphs[0].bounds.left) {
          // Next chord glyph is before the next lyric glyph
          mergedLine += '[${chordGlyphs.removeAt(0).text}]';
        } else {
          // Next lyric glyph is before the next chord glyph
          mergedLine += lyricGlyphs.removeAt(0).text;
        }
      }
    }

    return mergedLine;
  }

  String _formatChordOnlyLine(String chordLine) {
    // Formats a line that contains only chords into ChordPro format
    StringBuffer formattedLine = StringBuffer();

    RegExp chordRegex = RegExp(_chordPattern);
    List<RegExpMatch> matches = chordRegex.allMatches(chordLine).toList();
    for (var match in matches) {
      formattedLine.write('[');
      formattedLine.write(match.group(0));
      formattedLine.write(']');
    }

    return formattedLine.toString();
  }

  bool _isChordLine(String text) {
    // Simple regex to identify chord patterns (e.g., C, G7, Am, F#m)
    RegExp chordRegex = RegExp(_chordPattern);
    List<RegExpMatch> matches = chordRegex.allMatches(text).toList();

    // Check if the matches are part of a word
    List<RegExpMatch> matchesCopy = List.from(matches);
    for (var match in matchesCopy) {
      int start = match.start;
      int end = match.end;

      // Check character before the match
      if (start != 0) {
        String charBefore = text[start - 1];
        // Check if the character before the match is alphanumeric
        if (RegExp(r'[a-zA-Z0-9]').hasMatch(charBefore)) {
          // Match is part of a word
          matches.remove(match);
          continue;
        }
      }

      // Check character after the match
      if (end != text.length) {
        String charAfter = text[end];
        // Check if the character after the match is alphanumeric
        if (RegExp(r'[a-zA-Z0-9]').hasMatch(charAfter)) {
          // Match is part of a word
          matches.remove(match);
          continue;
        }
      }
    }

    // Heuristic: at least half of the words should match chord patterns
    if (matches.length < (text.split(RegExp(r'\s+')).length / 2)) {
      return false;
    }

    return true;
  }
}
