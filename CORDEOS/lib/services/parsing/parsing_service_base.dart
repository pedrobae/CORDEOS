import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/services/parsing/chord_line_parser.dart';
import 'package:cordeos/services/parsing/section_parser.dart';

class ParsingServiceBase {
  final ChordLineParser chordLineParser = ChordLineParser();
  final SectionParser sectionParser = SectionParser();

  ParsingResult parse(ParsingResult result) {
    parseSections(result);
    parseChords(result);
    return result;
  }

  void parseSections(ParsingResult result) {
    switch (result.strategy) {
      case ParsingStrategy.doubleNewLine:
        sectionParser.parseByEmptyLine(result);
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
  VersionDto buildVersionFromResult(ParsingResult result) {
    return VersionDto(
      sections: result.parsedSections,
      songStructure: result.songStructure,
      bpm: result.metadata['bpm'] ?? 0,
      versionName: 'Imported',
      duration: result.metadata['duration'] ?? 0,
      title: result.metadata['title'] ?? 'Unknown Title',
      author: result.metadata['author'] ?? 'Unknown Author',
      language: result.metadata['language'] ?? '',
      originalKey: result.metadata['key'] ?? '',
      links: result.metadata['links'] != null
          ? List<String>.from(result.metadata['tags'])
          : [],
      notes: result.metadata['annotations'],

      tags: result.metadata['tags'] != null
          ? List<String>.from(result.metadata['tags'])
          : [],
    );
  }
}
