import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/models/dtos/pdf_dto.dart';
import 'package:cordeos/utils/section_type.dart';

enum SeparatorType { emptyLine, bracket, parenthesis, hyphen }

class SectionParser {
  void parseByEmptyLine(ParsingResult result) {
    List<String> rawSections = [];
    final StringBuffer buffer = StringBuffer();
    for (var line in result.lines) {
      if (line.text.trim().isEmpty) {
        // EMPTY LINE - Section break
        rawSections.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.writeln(line.text);
      }
    }

    if (buffer.isNotEmpty) {
      rawSections.add(buffer.toString());
    }

    for (int i = 0; i < rawSections.length; i++) {
      String sectionContent = rawSections[i].trimRight();
      if (sectionContent.isEmpty) {
        continue; // Skip empty sections
      }

      RawSection section = RawSection(
        index: i,
        content: sectionContent,
        numberOfLines: sectionContent.split('\n').length,
        duplicateOf: null,
        suggestedLabel: SectionType.unknown.canonicalLabel,
        color: SectionType.unknown.color,
        key: i,
      );

      result.rawSections.add(section);
    }
  }

  void parseBySectionLabels(ParsingResult result) {
    String rawText = result.rawText;
    List<Map<String, dynamic>> validMatches = [];
    // Search common label texts
    for (var sectionType in SectionType.values) {
      for (var labelVariation in sectionType.knownLabels) {
        RegExp regex = RegExp(labelVariation, caseSensitive: false);
        Iterable<RegExpMatch> matches = regex.allMatches(result.rawText);

        for (var match in matches) {
          final labelData = _validateLabel(result.rawText, match);

          // Possible Label found -  Validate
          if (labelData['isValid']) {
            validMatches.add({
              'label': sectionType,
              'labelStart': labelData['labelStart'],
              'labelEnd': labelData['labelEnd'],
            });
          }
        }
      }
    }
    // Order valid matches by their position in the text
    validMatches.sort((a, b) => a['labelStart'].compareTo(b['labelStart']));

    for (int i = 0; i < validMatches.length; i++) {
      var match = validMatches[i];
      var nextMatch = (i + 1 < validMatches.length)
          ? validMatches[i + 1]
          : null;
      int sectionStart = match['labelEnd'];
      int sectionEnd = nextMatch != null
          ? nextMatch['labelStart']
          : rawText.length;
      SectionType label = match['label'];

      final content = rawText.substring(sectionStart, sectionEnd).trimRight();
      if (content.isEmpty) {
        continue; // Skip empty sections
      }

      result.rawSections.add(
        RawSection(
          index: result.rawSections.length,
          suggestedLabel: label.canonicalLabel,
          key: result.rawSections.length,
          color: label.color,
          content: content,
          numberOfLines: content.split('\n').length,
          duplicateOf: null,
        ),
      );
    }
    _checkDuplicates(result);
  }

  void parseByPdfFormatting(ParsingResult result) {
    /// Identifies section break based on line spacing greater than the mean line spacing
    double totalLineSpacing = 0.0;
    int relativeSpacingCount = 0;
    for (int i = 0; i < result.lines.length - 1; i++) {
      final textLine = result.lines[i];
      final nextLine = result.lines[i + 1];
      final spacing = nextLine.bounds!.top - textLine.bounds!.bottom;
      if (spacing > 0) {
        totalLineSpacing += spacing;
        relativeSpacingCount++;
      }
    }
    double meanLineSpacing = totalLineSpacing / relativeSpacingCount;
    int previousBreakIndex = 0;
    for (int i = 0; i < result.lines.length - 1; i++) {
      final textLine = result.lines[i];
      final nextLine = result.lines[i + 1];
      double lineSpacing = nextLine.bounds!.top - textLine.bounds!.bottom;
      // Line spacing greater than mean indicates a section break (negative spacing implies column change)
      if (lineSpacing > meanLineSpacing || lineSpacing < 0) {
        // Section break found
        int sectionStart = previousBreakIndex;
        int sectionEnd = i + 1;

        List<LineData> sectionLines = result.lines.sublist(
          sectionStart,
          sectionEnd,
        );

        _mapSectionFromLinesData(result, sectionLines);

        previousBreakIndex = sectionEnd;
      }
    }
    // Handle last section if any lines remain
    if (previousBreakIndex < result.lines.length) {
      List<LineData> sectionLines = result.lines.sublist(previousBreakIndex);

      _mapSectionFromLinesData(result, sectionLines);
    }

    _checkDuplicates(result);
  }

  /// Validates if a found label is indeed a section label,
  /// returns true if valid, false otherwise, {'isValid': bool, ...}
  /// and additional info for extracting the section {... , 'labelStart': int, 'labelEnd': int}, if valid
  Map<String, dynamic> _validateLabel(String rawText, RegExpMatch match) {
    /// Validation strategy - check surrounding characters
    /// Examples to correctly validade:
    /// "\nChorus\n"  -> valid
    /// "[Chorus]"    -> valid
    /// "(Chorus)"    -> valid
    /// "- Chorus -"  -> valid
    /// "Chorus:"      -> valid
    /// "Intro: C E F" -> valid -> Correctly identify the label at the start of the line
    /// "Verse 1"      -> valid
    /// "[Intro] A2  B2  C#m7  G#m7(11)" -> valid
    /// "First Verse" -> valid

    /// Invalid examples:
    /// "Cantaremos como um coro de anjos" -> invalid
    /// "This is the chorus of the song"   -> invalid
    /// "Chorus is a great part"            -> invalid

    int start = match.start;
    int end = match.end;

    // Extract the full line containing the match
    String matchLine = '';
    int lineStart = rawText.lastIndexOf('\n', start) + 1;
    int lineEnd = rawText.indexOf('\n', end);
    if (lineEnd == -1) {
      if (lineStart != 0) {
        // No newline was found after the match
        // And the text is not single line
        return {'isValid': false};
      }
      matchLine = rawText;
    } else {
      matchLine = rawText.substring(lineStart, lineEnd);
    }

    // Search for colon after the label
    RegExp colonRegex = RegExp(r':');
    if (colonRegex.hasMatch(matchLine)) {
      final labelEnd = colonRegex.firstMatch(matchLine)!.end;
      return {
        'isValid': true,
        'labelStart': lineStart,
        'labelEnd': lineStart + labelEnd,
        'labelWithColon': true,
      };
    }

    // Check if label is at or near the end of line (e.g., "First Verse")
    String afterMatch = rawText.substring(end).trimRight();
    bool isAtLineEnd = afterMatch.isEmpty || afterMatch.startsWith('\n');

    if (isAtLineEnd) {
      // Label is at end of line - valid (e.g., "First Verse" or "Verse 1")
      return {'isValid': true, 'labelStart': lineStart, 'labelEnd': end};
    }

    // Check preceding and following characters, examining equally spaced characters
    if (start - lineStart > lineEnd - end) {
      // More preceding characters than following characters ---> ASSUMING THIS ISNT A VALID LABEL
      if (lineEnd != -1) {
        return {'isValid': false};
      }
    }
    int j = 0;
    for (int i = start - 1; i >= lineStart; i--, j++) {
      String precedingChar = rawText[i];
      String followingChar = rawText[end + j];

      if (precedingChar != followingChar &&
          !_areMirrored(precedingChar, followingChar)) {
        // Mismatched characters, check for label suffixes, e.g. numbered verses ("Verse 1")
        if (followingChar.trim().isEmpty && _isNumber(rawText[end + j + 1])) {
          // The matched label is followed by a space and number,
          // Adjust indexes and continue checking
          i--;
          j += 2; // Skip space and number
          continue;
        } else {
          // Invalid label
          return {'isValid': false};
        }
      }
    }
    // All preceding and following characters matched
    return {'isValid': true, 'labelStart': lineStart, 'labelEnd': end + j};
  }

  bool _areMirrored(String char1, String char2) {
    const Map<String, String> mirroredPairs = {
      '(': ')',
      '[': ']',
      '{': '}',
      '<': '>',
      '-': '-',
    };

    return mirroredPairs[char1] == char2;
  }

  void _checkDuplicates(ParsingResult result) {
    // Check for duplicate content and mark them
    List<RawSection> sections = result.rawSections;
    Map<String, int> seenContentKeys = {};
    for (var section in sections) {
      String content = section.content;

      if (seenContentKeys.containsKey(content)) {
        section.duplicateOf = seenContentKeys[content];
      } else {
        seenContentKeys[content] = section.key;
      }
    }
  }

  void _mapSectionFromLinesData(
    ParsingResult result,
    List<LineData> linesData,
  ) {
    if (linesData.isEmpty) {
      return; // No lines to process
    }
    // Check first line for label
    bool firstLineHasLabel;
    RegExpMatch? match;
    SectionType label;
    (firstLineHasLabel, match, label) = _containsLabel(linesData[0].text);

    if (firstLineHasLabel) {
      final labelData = _validateLabel(linesData[0].text, match!);

      if (labelData['isValid']) {
        // Remove label from LineData
        linesData[0].text = linesData[0].text.substring(labelData['labelEnd']);

        if (linesData[0].text.trim().isEmpty) {
          // If the line is now empty, remove it from linesData
          linesData.removeAt(0);
        }
      }
    }
    StringBuffer buffer = StringBuffer();
    for (var line in linesData) {
      buffer.writeln(line.text);
    }
    String sectionContent = buffer.toString().trimRight();

    if (sectionContent.isEmpty) {
      return; // Skip empty sections
    }

    RawSection section = RawSection(
      index: result.rawSections.length,
      key: result.rawSections.length,
      content: sectionContent,
      numberOfLines: linesData.length,
      duplicateOf: null,
      suggestedLabel: label.canonicalLabel,
      linesData: linesData,
      color: label.color,
    );

    result.rawSections.add(section);
  }

  (bool, RegExpMatch?, SectionType) _containsLabel(String text) {
    for (var type in SectionType.values) {
      for (var labelVariation in type.knownLabels) {
        RegExp regex = RegExp(labelVariation, caseSensitive: false);
        if (regex.hasMatch(text)) {
          return (true, regex.firstMatch(text)!, type);
        }
      }
    }
    return (false, null, SectionType.unknown);
  }
}

bool _isNumber(String char) {
  return int.tryParse(char) != null;
}
