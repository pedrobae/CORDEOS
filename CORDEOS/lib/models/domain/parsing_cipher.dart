import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/dtos/pdf_dto.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:flutter/material.dart';

enum ImportType { text, pdf, image, spreadSheet }

/// Import strategy variants - different ways to extract text from source
/// Used when the same import type has multiple extraction methods
enum ImportVariation {
  pdfWithColumns, // PDF with column detection applied
  pdfNoColumns, // PDF without column detection
  textDirect, // Plain text as-is
  imageOcr, // Image with OCR
}

// extension to get localized names
extension ImportVariationExtension on ImportVariation {
  String getName(BuildContext context) {
    switch (this) {
      case ImportVariation.pdfWithColumns:
        return AppLocalizations.of(context)!.pdfWithColumns;
      case ImportVariation.pdfNoColumns:
        return AppLocalizations.of(context)!.pdfNoColumns;
      case ImportVariation.textDirect:
        return AppLocalizations.of(context)!.textDirect;
      case ImportVariation.imageOcr:
        return AppLocalizations.of(context)!.imageOcr;
    }
  }
}

/// Available parsing strategies for converting imported text to cipher sections
enum ParsingStrategy { doubleNewLine, sectionLabels, pdfFormatting }

// extension to get localized string names
extension ParsingStrategyExtension on ParsingStrategy {
  String getName(BuildContext context) {
    switch (this) {
      case ParsingStrategy.doubleNewLine:
        return AppLocalizations.of(context)!.doubleNewLine;
      case ParsingStrategy.sectionLabels:
        return AppLocalizations.of(context)!.sectionLabels;
      case ParsingStrategy.pdfFormatting:
        return AppLocalizations.of(context)!.pdfFormatting;
    }
  }
}

/// Mapping of import type to their applicable parsing strategies
Map<ImportType, List<ParsingStrategy>> importTypeToParsingStrategies = {
  ImportType.pdf: [ParsingStrategy.pdfFormatting],
  ImportType.text: [
    ParsingStrategy.doubleNewLine,
    ParsingStrategy.sectionLabels,
  ],
  ImportType.image: [],
};

// Mapping of import type to their applicable import variations
Map<ImportType, List<ImportVariation>> importTypeToVariations = {
  ImportType.pdf: [
    ImportVariation.pdfWithColumns,
    ImportVariation.pdfNoColumns,
  ],
  ImportType.text: [ImportVariation.textDirect],
  ImportType.image: [ImportVariation.imageOcr],
};

/// Container for results from a single parsing strategy
class ParsingResult {
  final ParsingStrategy strategy;
  final String rawText;

  final List<LineData> lines = [];
  final Map<String, dynamic> metadata = {};
  final List<RawSection> rawSections = [];
  final Map<int, SectionDto> parsedSections = {};
  final List<int> songStructure = [];

  ParsingResult({required this.strategy, required this.rawText});

  /// Check if this result has any parsed content
  bool get hasContent => parsedSections.isNotEmpty || rawSections.isNotEmpty;

  /// Get the number of sections found
  int get sectionCount => parsedSections.length;
}

/// Main cipher parsing container that holds imported text and all import variants
class ParsingCipher {
  final ImportType importType;
  ParsingResult result;

  ParsingCipher({required this.importType, required this.result});
}

class RawSection {
  String suggestedLabel;
  Color color;
  String content;
  List<LineData>? linesData;
  int key;
  int index;
  int numberOfLines;
  int? duplicateOf; // If duplicate, holds the key of the original section

  RawSection({
    required this.suggestedLabel,
    required this.color,
    required this.content,
    required this.index,
    required this.numberOfLines,
    required this.key,
    this.linesData,
    this.duplicateOf,
  });
}
