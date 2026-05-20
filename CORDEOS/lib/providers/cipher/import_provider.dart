import 'package:collection/collection.dart';
import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/models/dtos/pdf_dto.dart';
import 'package:cordeos/services/import/spreadsheet_import_service.dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:cordeos/services/import/pdf_import_service.dart';

class ImportFile extends PlatformFile {
  ParsingStrategy parsingStrategy;
  ImportVariation importVariation;
  ImportType importType;

  ImportFile({
    required this.importType,
    required this.parsingStrategy,
    required this.importVariation,
    required super.path,
    required super.name,
    required super.size,
  });

  @override
  bool operator ==(Object other) {
    return other is ImportFile &&
        importType == other.importType &&
        parsingStrategy == other.parsingStrategy &&
        importVariation == other.importVariation &&
        path == other.path &&
        name == other.name &&
        size == other.size;
  }

  @override
  int get hashCode {
    return (importType.hashCode +
            parsingStrategy.hashCode +
            importVariation.hashCode +
            path.hashCode +
            name.hashCode +
            size.hashCode) ~/
        6;
  }
}

class ImportProvider extends ChangeNotifier {
  final PDFImportService _pdfService = PDFImportService();
  // final ImageImportService _imageService = ImageImportService();
  final SpreadsheetImportService _spreadSheetService =
      SpreadsheetImportService();

  /// Single ParsingCipher object that may contain multiple import variants
  bool _isImporting = false;
  List<ImportFile> _files = [];
  String? _error;

  List<ImportFile> get files => _files;
  bool get isImporting => _isImporting;
  String? get error => _error;

  bool hasColumns(file) {
    return files.firstWhereOrNull((file) => file == file)?.importVariation ==
        ImportVariation.pdfWithColumns;
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
      for (final file in files)
        switch (file.importType) {
          case ImportType.text:
            // Text import: single import variant (textDirect)
            final import = ParsingCipher(
              result: ParsingResult(
                strategy: file.parsingStrategy,
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
            for (final file in files) {
              final pdfDocument = await _pdfService.extractTextWithFormatting(
                file.path!,
                file.name,
                file.importVariation == ImportVariation.pdfWithColumns,
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
            }

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
            final data = await _spreadSheetService.extractData(
              files.first.path!,
            );
            for (final sheetLine in data) {
              final import = ParsingCipher(
                result: ParsingResult(
                  strategy: ParsingStrategy.emptyLine,
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
  void addFile(ImportFile file) {
    _files.add(file);
    notifyListeners();
  }

  /// Clears the selected file name.
  void removeFileAt(int index) {
    _files.removeAt(index);
    notifyListeners();
  }

  /// Clears any existing error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    _isImporting = false;
    _files = [];
    _error = null;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}
