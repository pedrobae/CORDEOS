import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:cordis/models/dtos/pdf_dto.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/services/parsing/chord_line_parser.dart';
import 'package:cordis/services/parsing/section_parser.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ParsingServiceBase {
  final ChordLineParser chordLineParser = ChordLineParser();
  final SectionParser sectionParser = SectionParser();

  void parse(ParsingResult result) {
    parseSections(result);
    parseChords(result);
  }

  void parseSections(ParsingResult result) {
    switch (result.strategy) {
      case ParsingStrategy.doubleNewLine:
        sectionParser.parseByDoubleNewLine(result);
        break;
      case ParsingStrategy.sectionLabels:
        sectionParser.parseBySectionLabels(result);
        break;
      case ParsingStrategy.pdfFormatting:
        sectionParser.parseByPdfFormatting(result);
        break;
    }
  }

  void parseChords(ParsingResult result) {
    switch (result.strategy) {
      case ParsingStrategy.doubleNewLine:
      case ParsingStrategy.sectionLabels:
        chordLineParser.parseBySimpleText(result);
        break;
      case ParsingStrategy.pdfFormatting:
        chordLineParser.parseByPdfFormatting(result);
        break;
    }
  }

  /// ----- PRE-PROCESSING HELPERS ------
  void preProcessPdf(ParsingResult result) {
    /// PRE-PROCESSING STEPS
    /// - Initialize the PDF-specific parsing result
    /// - Identify different font styles used in the document
    /// - Calculate average space between words for each line
    for (int i = 0; i < result.lines.length; i++) {
      final textLine = result.lines[i];
      final followingLine = (i + 1 < result.lines.length)
          ? result.lines[i + 1]
          : null;

      // Keep count of font styles
      final fontStyles = textLine.fontStyle ?? [];
      result.fontStyleCount[(fontStyles)] =
          (result.fontStyleCount[(fontStyles)] ?? 0) + 1;

      // Keep count of adjacent font styles
      if (result.followingStyleCounts[(fontStyles)] == null) {
        result.followingStyleCounts[(fontStyles)] = {};
      }
      if (followingLine != null) {
        result.followingStyleCounts[(fontStyles)]![(followingLine.fontStyle ??
                [])] =
            (result.followingStyleCounts[(fontStyles)]![(followingLine
                        .fontStyle ??
                    [])] ??
                0) +
            1;
      }

      // Calculate average space between words and average word length
      final words = textLine.wordList;
      if (words!.length > 1) {
        int totalSpace = 0;
        for (int i = 0; i < words.length - 1; i++) {
          totalSpace +=
              words[i + 1].bounds.left.toInt() - words[i].bounds.right.toInt();
        }
        textLine.avgSpaceBetweenWords = totalSpace ~/ (words.length - 1);
      } else {
        textLine.avgSpaceBetweenWords = 0;
      }
    }

    // - Identify Chord Style
    //     - Heuristic: at least 30% of lines use this style
    //     - Heuristic: at least 70% of chord lines have the same following style (lyrics style)
    //     - Heuristic: chord lines have higher average space between words
    final int totalLines = result.lines.length;
    List<List<PdfFontStyle>> possibleChordStyles = [];
    for (var entry in result.fontStyleCount.entries) {
      final style = entry.key;
      final count = entry.value;
      // Check style usage threshold
      if (count / totalLines >= 0.3) {
        // Check following styles
        if (result.followingStyleCounts[style]!.values.any(
          (s) => s > count * 0.7,
        )) {
          // Potential chord style found
          possibleChordStyles.add(style);
        }
      }
    }
    // From possible chord styles, select the one with highest average space between words
    int highestAvgSpace = -1;
    for (var style in possibleChordStyles) {
      int totalSpace = 0;
      for (var textLine in result.lines) {
        if ((textLine.fontStyle ?? []) == style) {
          totalSpace += textLine.avgSpaceBetweenWords!;
        }
      }
      int avgSpace = totalSpace ~/ result.fontStyleCount[style]!;
      if (avgSpace > highestAvgSpace) {
        highestAvgSpace = avgSpace;
        result.dominantChordStyle = style;
      }
    }
  }

  void calculateLines(ParsingResult result) {
    final rawLines = result.rawText.split('\n');
    for (var i = 0; i < rawLines.length; i++) {
      var line = rawLines[i];
      // Split line text into words using whitespace as delimiter
      List<String> words = line.split(RegExp(r'\s+')).toList();

      // Calculate average word length
      double avgWordLength = words.isNotEmpty
          ? words.map((w) => w.length).reduce((a, b) => a + b) / words.length
          : 0.0;

      result.lines.add(
        LineData(
          wordCount: words.length,
          avgWordLength: avgWordLength,
          text: line,
          lineIndex: i,
        ),
      );
    }
  }

  VersionDto buildVersionFromResult(ParsingResult result) {
    return VersionDto(
      sections: result.parsedSections,
      songStructure: result.songStructure,
      bpm: result.metadata['bpm'] ?? 0,
      versionName: 'Imported',
      duration: result.metadata['duration'] ?? 0,
      title: result.metadata['title'] ?? 'Unknown Title',
      author: result.metadata['artist'] ?? 'Unknown Artist',
      language: result.metadata['language'] ?? '',
      originalKey: '',
      tags: result.metadata['tags'] != null
          ? List<String>.from(result.metadata['tags'])
          : [],

    );
  }
}
