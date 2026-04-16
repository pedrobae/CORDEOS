import 'dart:io';
import 'package:cordeos/helpers/pdf_glyph_extractor.dart';
import 'package:cordeos/models/dtos/pdf_dto.dart';
import 'package:cordeos/services/import/import_service_base.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFImportService extends ImportService {
  /// Extracts text content from a PDF file
  ///
  /// [path] - Absolute file path to the PDF
  /// Returns extracted text as a String
  /// Throws [FileSystemException] if file doesn't exist
  /// Throws [Exception] if PDF parsing fails
  @override
  Future<String> extractText(String path) async {
    try {
      // Read PDF file as bytes
      final file = File(path);
      final bytes = await file.readAsBytes();

      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text using Syncfusion's text extractor
      final String text = PdfTextExtractor(document).extractText();

      // Clean up resources
      document.dispose();

      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extracts text with detailed formatting information for better parsing
  ///
  /// Returns a list of text lines with font size, boldness, and position metadata
  Future<DocumentData> extractTextWithFormatting(
    String path,
    String fileName,
    bool hasColumns,
  ) async {
    PdfDocument? document;
    try {
      final bytes = await File(path).readAsBytes();
      document = PdfDocument(inputBytes: bytes);

      // Extract glyphs per page directly from renderer glyph list
      final Map<int, List<TextGlyph>> pageGlyphs = {};
      final int pagesToProcess = document.pages.count;

      for (int i = 0; i < pagesToProcess; i++) {
        pageGlyphs[i] = PdfGlyphExtractorHelper.extractPageGlyphs(document, i);
      }

      // Sort glyphs by their vertical position (top)
      for (var pageGlyphList in pageGlyphs.values) {
        pageGlyphList.sort((a, b) {
          return a.bounds.top.compareTo(b.bounds.top);
        });
      }

      final DocumentData documentData = DocumentData.fromGlyphMap(
        pageGlyphs,
        fileName,
      );

      if (hasColumns) {
        final pageLines = documentData.reorderByColumns();
        documentData.pageLines = pageLines;
      }
      
      return documentData;
    } catch (e) {
      throw Exception('Failed to extract formatted text from PDF: $e');
    } finally {
      document?.dispose();
    }
  }

  /// Validates that the PDF file exists and has .pdf extension
  @override
  Future<bool> validate(String path) async {
    if (!path.toLowerCase().endsWith('.pdf')) {
      return false;
    }

    final file = File(path);
    return await file.exists();
  }
}
