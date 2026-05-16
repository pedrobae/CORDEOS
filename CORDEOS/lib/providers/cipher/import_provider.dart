import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/models/dtos/pdf_dto.dart';
import 'package:cordeos/services/import/spreadsheet_import_service.dart.dart';
import 'package:flutter/foundation.dart';
import 'package:cordeos/services/import/pdf_import_service.dart';

class ImportProvider extends ChangeNotifier {
  final PDFImportService _pdfService = PDFImportService();
  // final ImageImportService _imageService = ImageImportService();
  final SpreadsheetImportService _spreadSheetService =
      SpreadsheetImportService();

  /// Single ParsingCipher object that may contain multiple import variants
  bool _isImporting = false;
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  String? _error;
  ImportType? _importType;
  ParsingStrategy? _parsingStrategy;
  ImportVariation? _importVariation;

  String? get filePath => _filePath;
  String? get fileName => _fileName;
  String? get fileSize => _parseFileSize(_fileSize);
  bool get isImporting => _isImporting;
  String? get error => _error;
  ImportType? get importType => _importType;
  ParsingStrategy? get parsingStrategy => _parsingStrategy;
  ImportVariation? get importVariation => _importVariation;

  /// Sets the import type (text, pdf, image).
  void setImportType(ImportType type) {
    _importType = type;
  }

  /// Toggles the parsing strategy between double new line and section labels.
  void toggleParsingStrategy() {
    _parsingStrategy = _parsingStrategy == ParsingStrategy.doubleNewLine
        ? ParsingStrategy.sectionLabels
        : ParsingStrategy.doubleNewLine;
    notifyListeners();
  }

  void setParsingStrategy(ParsingStrategy strategy) {
    _parsingStrategy = strategy;
    notifyListeners();
  }

  void setImportVariation(ImportVariation variation) {
    _importVariation = variation;
    notifyListeners();
  }

  /// Imports text based on the selected import type.
  /// For PDFs: creates multiple import variants (with/without columns) in a single ParsingCipher
  /// For text/images: creates a single import variant
  Future<List<ParsingCipher>> importText({String? data}) async {
    final imports = <ParsingCipher>[];
    if (_isImporting) return imports;

    _isImporting = true;
    _error = null;
    notifyListeners();

    try {
      switch (_importType) {
        case ImportType.text:
          // Text import: single import variant (textDirect)
          final import = ParsingCipher(
            result: ParsingResult(
              strategy: _parsingStrategy!,
              rawText: data ?? '',
            ),
            importType: ImportType.text,
          );

          final rawLines = data?.split('\n') ?? [];
          for (var i = 0; i < rawLines.length; i++) {
            var line = rawLines[i];
            // Split line text into words using whitespace as delimiter
            List<String> words = line.split(RegExp(r'\s+')).toList();
            import.result.lines.add(
              LineData(wordCount: words.length, text: line, lineIndex: i),
            );
          }
          imports.add(import);
          break;

        case ImportType.pdf:
          // PDF import: multiple import variants (with/without columns)
          final pdfDocument = await _pdfService.extractTextWithFormatting(
            filePath!,
            fileName!,
            _importVariation == ImportVariation.pdfWithColumns,
          );

          final import = ParsingCipher(
            importType: ImportType.pdf,
            result: ParsingResult(
              strategy: ParsingStrategy.pdfFormatting,
              rawText: '',
            ),
          );

          import.result.metadata['title'] = pdfDocument.documentName
              .split('.') // remove file extension
              .first;

          final importedLines = pdfDocument.lines;

          if (importedLines.isEmpty) {
            throw Exception('No text lines were extracted from the PDF');
          }

          import.result.lines.addAll(importedLines);
          imports.add(import);
          break;

        case ImportType.image:
          // final text = await _imageService.extractText(filePath!);
          // final import = ParsingCipher(
          //   result: ParsingResult(
          //     strategy: ParsingStrategy.pdfFormatting,
          //     rawText: text,
          //   ),
          //   importType: ImportType.image,
          // );
          // imports.add(import);
          break;
        case ImportType.spreadSheet:
          final data = await _spreadSheetService.extractData(filePath!);
          for (final sheetLine in data) {
            final import = ParsingCipher(
              result: ParsingResult(
                strategy: ParsingStrategy.doubleNewLine,
                rawText: sheetLine.content,
              ),
              importType: ImportType.spreadSheet,
            );
            import.result.metadata.addAll(sheetLine.metadata);
            final rawLines = sheetLine.content.split('\n');
            for (var i = 0; i < rawLines.length; i++) {
              var sheetLine = rawLines[i];
              // Split line text into words using whitespace as delimiter
              List<String> words = sheetLine.split(RegExp(r'\s+')).toList();
              import.result.lines.add(
                LineData(
                  wordCount: words.length,
                  text: sheetLine,
                  lineIndex: i,
                ),
              );
            }
            imports.add(import);
          }
          break;
        case null:
          throw Exception('Import type must be selected before importing');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isImporting = false;
      notifyListeners();
    }
    return imports;
  }

  /// Sets the selected file name.
  void setSelectedFile(String filePath, {int? fileSize, String? fileName}) {
    _filePath = filePath;
    _fileSize = fileSize;
    _fileName = fileName;
    notifyListeners();
  }

  /// Clears the selected file name.
  void clearSelectedFile() {
    _filePath = null;
    notifyListeners();
  }

  /// Clears the selected file name.
  void clearSelectedFileName() {
    _fileName = null;
    notifyListeners();
  }

  /// Clears any existing error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    _isImporting = false;
    _filePath = null;
    _fileName = null;
    _error = null;
    _importType = null;
    _parsingStrategy = null;
    _importVariation = null;
    notifyListeners();
  }

  String? _parseFileSize(int? sizeInBytes) {
    if (sizeInBytes == null) return null;
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    }
    if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
