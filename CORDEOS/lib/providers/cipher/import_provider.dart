import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:flutter/foundation.dart';
import 'package:cordeos/services/import/image_import_service.dart';
import 'package:cordeos/services/import/pdf_import_service.dart';

class ImportProvider extends ChangeNotifier {
  final PDFImportService _pdfService = PDFImportService();
  final ImageImportService _imageService = ImageImportService();

  /// Single ParsingCipher object that may contain multiple import variants
  bool _isImporting = false;
  String? _selectedFile;
  String? _selectedFileName;
  int? _fileSize;
  String? _error;
  ImportType? _importType;
  ParsingStrategy? _parsingStrategy;
  ImportVariation? _importVariation;

  String? get selectedFile => _selectedFile;
  String? get selectedFileName => _selectedFileName;
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
  Future<ParsingCipher?> importText({String? data}) async {
    if (_isImporting) return null;

    _isImporting = true;
    _error = null;
    notifyListeners();

    ParsingCipher? importedCipher;
    try {
      switch (_importType) {
        case ImportType.text:
          // Text import: single import variant (textDirect)
          importedCipher = ParsingCipher(
            result: ParsingResult(
              strategy: _parsingStrategy!,
              rawText: data ?? '',
            ),
            importType: ImportType.text,
          );
          break;

        case ImportType.pdf:
          // PDF import: multiple import variants (with/without columns)
          final pdfDocument = await _pdfService.extractTextWithFormatting(
            selectedFile!,
            selectedFileName!,
            _importVariation == ImportVariation.pdfWithColumns,
          );

          importedCipher = ParsingCipher(
            importType: ImportType.pdf,
            result: ParsingResult(
              strategy: ParsingStrategy.pdfFormatting,
              rawText: '',
            ),
          );

          importedCipher.result.metadata['title'] = pdfDocument.documentName
              .split('.') // remove file extension
              .first;

          final importedLines = pdfDocument.lines;

          if (importedLines.isEmpty) {
            throw Exception('No text lines were extracted from the PDF');
          }

          importedCipher.result.lines.addAll(importedLines);
          break;

        case ImportType.image:
          final text = await _imageService.extractText(selectedFile!);
          importedCipher = ParsingCipher(
            result: ParsingResult(
              strategy: ParsingStrategy.pdfFormatting,
              rawText: text,
            ),
            importType: ImportType.image,
          );
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
    return importedCipher;
  }

  /// Sets the selected file name.
  void setSelectedFile(String filePath, {int? fileSize, String? fileName}) {
    _selectedFile = filePath;
    _fileSize = fileSize;
    _selectedFileName = fileName;
    notifyListeners();
  }

  /// Clears the selected file name.
  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  /// Clears the selected file name.
  void clearSelectedFileName() {
    _selectedFileName = null;
    notifyListeners();
  }

  /// Clears any existing error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    _isImporting = false;
    _selectedFile = null;
    _selectedFileName = null;
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
