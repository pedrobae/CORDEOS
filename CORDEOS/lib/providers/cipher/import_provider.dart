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
  final SpreadsheetImportService _spreadSheetService =
      SpreadsheetImportService();

  Future<ParsingCipher> importFromText(
    ParsingStrategy strategy,
    String rawText,
  ) async {
    final import = ParsingCipher(
      result: ParsingResult(strategy: strategy, rawText: rawText),
      importType: ImportType.text,
    );

    final rawLines = rawText.split('\n');
    for (var i = 0; i < rawLines.length; i++) {
      var line = rawLines[i];
      // Split line text into words using whitespace as delimiter
      List<String> words = line.split(RegExp(r'\s+')).toList();
      import.result.lines.add(
        LineData(wordCount: words.length, text: line, lineIndex: i),
      );
    }
    return import;
  }

  Future<ParsingCipher> importFromPDF(ImportFile file) async {
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

    final nameList = pdfDocument.documentName.split('.');
    nameList.removeLast();
    import.result.metadata.title = nameList.join();
    // remove file extension

    final importedLines = pdfDocument.lines;
    if (importedLines.isEmpty) {
      throw Exception('No text lines were extracted from the PDF');
    }

    import.result.lines.addAll(importedLines);
    return import;
  }

  Future<List<ParsingCipher>> importFromSpreadsheet(ImportFile file) async {
    final imports = <ParsingCipher>[];
    final data = await _spreadSheetService.extractData(file.path!);
    for (final sheetLine in data) {
      final import = ParsingCipher(
        result: ParsingResult(
          strategy: ParsingStrategy.emptyLine,
          rawText: sheetLine.content,
        ),
        importType: ImportType.spreadSheet,
      );
      import.result.metadata.fromSpreadSheetLine(sheetLine);
      final rawLines = sheetLine.content.split('\n');
      for (var i = 0; i < rawLines.length; i++) {
        var sheetLine = rawLines[i];
        // Split line text into words using whitespace as delimiter
        List<String> words = sheetLine.split(RegExp(r'\s+')).toList();
        import.result.lines.add(
          LineData(wordCount: words.length, text: sheetLine, lineIndex: i),
        );
      }
      imports.add(import);
    }
    return imports;
  }
}
