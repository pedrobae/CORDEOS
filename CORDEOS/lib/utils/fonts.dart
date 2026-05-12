import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum FontFamilies { openSans, asimovian, atkinson, caveat }

extension FontFamiliesMethods on FontFamilies {
  String get key {
    switch (this) {
      case FontFamilies.openSans:
        return 'OpenSans';
      case FontFamilies.asimovian:
        return 'Asimovian';
      case FontFamilies.atkinson:
        return 'Atkinson';
      case FontFamilies.caveat:
        return 'Caveat';
    }
  }

  /// Asset path to the font file (includes default regular variant)
  String get assetPath {
    switch (this) {
      case FontFamilies.openSans:
        return 'assets/fonts/OpenSans-VariableFont_wdth_wght.ttf';
      case FontFamilies.asimovian:
        return 'assets/fonts/Asimovian-Regular.ttf';
      case FontFamilies.atkinson:
        return 'assets/fonts/AtkinsonHyperlegible-Regular.ttf';
      case FontFamilies.caveat:
        return 'assets/fonts/Caveat-VariableFont_wght.ttf';
    }
  }

  /// Get font asset path for a specific style variant
  /// Returns the best matching variant or falls back to default
  String getAssetPathForWeight(bool isBold, bool isItalic) {
    switch (this) {
      case FontFamilies.openSans:
        if (isBold && isItalic) {
          return 'assets/fonts/OpenSans-Italic-VariableFont_wdth_wght.ttf';
        } else if (isItalic) {
          return 'assets/fonts/OpenSans-Italic-VariableFont_wdth_wght.ttf';
        }
        return 'assets/fonts/OpenSans-VariableFont_wdth_wght.ttf';
      case FontFamilies.atkinson:
        if (isBold && isItalic) {
          return 'assets/fonts/AtkinsonHyperlegible-BoldItalic.ttf';
        } else if (isBold) {
          return 'assets/fonts/AtkinsonHyperlegible-Bold.ttf';
        } else if (isItalic) {
          return 'assets/fonts/AtkinsonHyperlegible-Italic.ttf';
        }
        return 'assets/fonts/AtkinsonHyperlegible-Regular.ttf';
      // Asimovian and Caveat only have single variants
      case FontFamilies.asimovian:
        return 'assets/fonts/Asimovian-Regular.ttf';
      case FontFamilies.caveat:
        return 'assets/fonts/Caveat-VariableFont_wght.ttf';
    }
  }

  /// Load font bytes from assets
  Future<Uint8List> loadFontBytes({
    bool isBold = false,
    bool isItalic = false,
  }) async {
    final path = getAssetPathForWeight(isBold, isItalic);
    return await rootBundle
        .load(path)
        .then((data) => data.buffer.asUint8List());
  }

  /// Find FontFamily enum from font name string
  static FontFamilies? fromName(String? fontName) {
    if (fontName == null) return null;
    try {
      return FontFamilies.values.firstWhere(
        (font) => font.key.toLowerCase() == fontName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

final Map<String, PdfFont> _fontCache = {};

/// Load a PDF font from the asset, using cache to avoid reloading
Future<PdfFont> getPdfFont(
  String fontName,
  double fontSize,
  double fontWeight, {
  bool isItalic = false,
}) async {
  final fontFamily = FontFamiliesMethods.fromName(fontName);
  if (fontFamily == null) {
    // Fallback to default font
    return PdfStandardFont(PdfFontFamily.helvetica, fontSize);
  }

  final cacheKey = '${fontFamily.key}_${fontWeight}_${isItalic}_$fontSize';

  // Return cached font if available
  if (_fontCache.containsKey(cacheKey)) {
    return _fontCache[cacheKey]!;
  }

  // Load and cache the font
  try {
    final fontBytes = await fontFamily.loadFontBytes(
      isBold: fontWeight > 600,
      isItalic: isItalic,
    );
    final pdfFont = PdfTrueTypeFont(
      fontBytes,
      fontSize,
      multiStyle: [
        if (fontWeight > 600) PdfFontStyle.bold,
        if (isItalic) PdfFontStyle.italic,
        PdfFontStyle.regular,
      ],
    );
    _fontCache[cacheKey] = pdfFont;
    return pdfFont;
  } catch (e) {
    debugPrint('Failed to load font $fontName: $e');
    // Fallback to standard font if loading fails
    return PdfStandardFont(PdfFontFamily.helvetica, fontSize);
  }
}
