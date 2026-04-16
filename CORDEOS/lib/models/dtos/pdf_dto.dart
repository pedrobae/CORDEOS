import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const double newLineThreshold = 2.0; // Tolerance for y-position differences
const double spaceThreshold = 1.0; // Threshold to detect spaces between words

class DocumentData {
  final String documentName;
  Map<int, List<LineData>> pageLines; // Original without column reordering

  DocumentData({required this.documentName, required this.pageLines});

  List<LineData> get lines {
    List<LineData> allLines = [];
    for (var lines in pageLines.values) {
      allLines.addAll(lines);
    }
    return allLines;
  }

  factory DocumentData.fromGlyphMap(
    Map<int, List<TextGlyph>> pageGlyphs,
    String docName,
  ) {
    Map<int, List<LineData>> pages = {};
    for (var pageGlyph in pageGlyphs.entries) {
      int currentLineIndex = -1;
      double lastY = -1.0;
      Map<int, List<TextGlyph>> lineGlyphMap = {};
      for (var glyph in pageGlyph.value) {
        // Check if glyph starts a new line
        if ((lastY - glyph.bounds.top).abs() > newLineThreshold ||
            lastY == -1.0) {
          currentLineIndex++;
          lastY = glyph.bounds.top;
        }

        // Add glyph to the current line, on the correct position (x-axis)
        if (lineGlyphMap[currentLineIndex] == null) {
          lineGlyphMap[currentLineIndex] = [glyph];
        } else {
          final lineGlyph = lineGlyphMap[currentLineIndex]!;
          bool inserted = false;
          for (int i = 0; i < lineGlyph.length; i++) {
            if (glyph.bounds.left < lineGlyph[i].bounds.left) {
              inserted = true;
              lineGlyph.insert(i, glyph);
              break;
            }
          }
          if (!inserted) {
            lineGlyph.add(glyph);
          }
        }
      }

      List<LineData> lines = [];
      for (var entry in lineGlyphMap.entries) {
        if (entry.value.any((g) => g.text.trim().isNotEmpty)) {
          lines.add(LineData.fromGlyphArray(entry.key, entry.value));
        }
      }
      pages[pageGlyph.key] = lines;
    }

    return DocumentData(documentName: docName, pageLines: pages);
  }

  /// Called when user indicates there is a column split,
  /// Find the split and reorder lines accordingly
  Map<int, List<LineData>> reorderByColumns() {
    // For each page count the number of words that have bounds at each x coordinate
    // X coordinate steps with a certain precision
    final Map<int, List<LineData>> pLines = {};
    double firstBound = double.infinity;
    double lastBound = double.negativeInfinity;
    for (var pageEntry in pageLines.entries) {
      // x coord -> number of words that have a bound at that x coord
      final Map<double, int> xPosWordCount = {};
      // Step between projected points when counting word bounds
      final precision = 1.0;

      for (var line in pageEntry.value) {
        for (var word in line.wordList!) {
          final firstPoint =
              ((word.bounds.left ~/ precision) * precision) + precision;
          for (double x = firstPoint; x <= word.bounds.right; x += precision) {
            xPosWordCount[x] = (xPosWordCount[x] ?? 0) + 1;
          }
          if (word.bounds.left < firstBound) {
            firstBound = word.bounds.left;
          }
          if (word.bounds.right > lastBound) {
            lastBound = word.bounds.right;
          }
        }
      }

      final gapRange = Rect.fromLTRB(
        (firstBound + ((lastBound - firstBound) / 4)),
        0,
        (lastBound - ((lastBound - firstBound) / 4)),
        0,
      );
      final divider = _decideGap(xPosWordCount, precision, gapRange);

      // Create the column-reordered version
      List<LineData> rightColumnLines = [];
      List<LineData> leftColumnLines = [];
      for (var line in pageEntry.value) {
        List<WordData> wordsInLeftColumn = [];
        List<WordData> wordsInRightColumn = [];
        bool metadataLine = false;
        for (var word in line.wordList!) {
          if (word.bounds.right < divider) {
            wordsInLeftColumn.add(word);
          } else if (word.bounds.left > divider) {
            wordsInRightColumn.add(word);
          } else {
            // The word is split by the divider,
            metadataLine = true;
            break;
          }
        }

        // If it is a metadata line, assign it to the left column
        if (metadataLine) {
          leftColumnLines.add(line.copy());
          continue;
        }

        if (wordsInRightColumn.isNotEmpty) {
          // There are words in the right column
          rightColumnLines.add(
            LineData(
              text: wordsInRightColumn.map((w) => w.text).join(' '),
              fontSize: line.fontSize,
              bounds: Rect.fromLTRB(
                wordsInRightColumn.first.bounds.left,
                line.bounds!.top,
                line.bounds!.right,
                line.bounds!.bottom,
              ),
              fontStyle: line.fontStyle,
              lineIndex: line.lineIndex,
              wordList: wordsInRightColumn,
            ),
          );
        }
        if (wordsInLeftColumn.isNotEmpty) {
          leftColumnLines.add(
            LineData(
              text: wordsInLeftColumn.map((w) => w.text).join(' '),
              fontSize: line.fontSize,
              bounds: Rect.fromLTRB(
                line.bounds!.left,
                line.bounds!.top,
                wordsInLeftColumn.last.bounds.right,
                line.bounds!.bottom,
              ),
              fontStyle: line.fontStyle,
              lineIndex: line.lineIndex,
              wordList: wordsInLeftColumn,
            ),
          );
        }
      }

      // Save the reordered version (left column, then right column)
      pLines[pageEntry.key] = [...leftColumnLines, ...rightColumnLines];
    }
    return pLines;
  }

  // Returns the x coordinate of the 'divider line' between columns,
  // Receives a map with x coordinates and the number of word bounds that have a bound at that x coordinate
  // The divider is chosen as the x coordinate with the minimum number of word bounds
  double _decideGap(
    Map<double, int> xPosWordCount,
    double precision,
    Rect gapRange,
  ) {
    final leftCoord = gapRange.left - (gapRange.left % precision);
    final rightCoord = gapRange.right - (gapRange.right % precision);
    // Search for 'holes' in the keySpace (x coordinates with no words)
    for (var coord = leftCoord; coord < rightCoord; coord += precision) {
      assert(() {
        if (coord % precision != 0) {
          throw Exception('Coord is not on the precision grid');
        }
        return true;
      }());
      if (xPosWordCount[coord] == null || xPosWordCount[coord] == 0) {
        // We found a hole, return the middle point as divider
        return coord;
      }
    }

    // There are no holes
    // calculate the 'area' of 'valleys' in the distribution (consecutive x coords between local maxima)
    // return the local minimum with the largest area (largest gap between local maxima)
    List<double> localMaxima = [];
    for (var coord = leftCoord; coord < rightCoord; coord += precision) {
      final previous = coord - precision;
      final current = coord;
      final next = coord + precision;
      if (xPosWordCount[previous]! < xPosWordCount[current]! &&
          xPosWordCount[next]! < xPosWordCount[current]!) {
        localMaxima.add(current);
      }
    }
    double maxArea = 0;
    double valleyMinCoord = leftCoord;
    for (var i = 0; i < localMaxima.length - 1; i++) {
      final valleyRange = List.generate(
        (localMaxima[i + 1] - localMaxima[i] - 1) ~/ precision,
        (index) => localMaxima[i] + (index * precision),
      );
      final highestMax = localMaxima[i] > localMaxima[i + 1]
          ? localMaxima[i]
          : localMaxima[i + 1];
      double area = 0;
      for (var coord in valleyRange) {
        area += highestMax - (xPosWordCount[coord]!);
      }
      if (area > maxArea) {
        maxArea = area;
        // Find the valley minimum
        valleyMinCoord = localMaxima[i];
        int valleyMin = xPosWordCount[valleyMinCoord]!;
        for (var coord in valleyRange) {
          if (xPosWordCount[coord]! < valleyMin) {
            valleyMin = xPosWordCount[coord]!;
            valleyMinCoord = coord;
          }
        }
      }
    }
    return valleyMinCoord;
  }
}

class LineData {
  String text;
  final double? fontSize;
  final Rect? bounds;
  final List<PdfFontStyle>? fontStyle;
  final int? wordCount;
  final int lineIndex;
  final List<WordData>? wordList;

  LineData({
    this.wordCount,
    required this.text,
    this.fontSize,
    this.bounds,
    this.fontStyle,
    required this.lineIndex,
    this.wordList,
  });

  int get pdfWordCount => wordList!.length;

  LineData copy() {
    return LineData(
      text: text,
      fontSize: fontSize,
      bounds: bounds,
      fontStyle: fontStyle,
      lineIndex: lineIndex,
      wordList: wordList,
    );
  }

  factory LineData.fromGlyphArray(int lineIndex, List<TextGlyph> glyphs) {
    Map<int, List<TextGlyph>> wordGlyphMap = {};
    int currentWordIndex = -1;
    double lastRightBound = 0.0;
    for (var glyph in glyphs) {
      // Check if glyph is a space
      if (glyph.text.trim().isEmpty) {
        continue; // Trim spaces
      }
      if ((glyph.bounds.left - lastRightBound) > spaceThreshold ||
          currentWordIndex == -1) {
        currentWordIndex++;
      }
      // Add glyph to the current word
      if (wordGlyphMap[currentWordIndex] == null) {
        wordGlyphMap[currentWordIndex] = [glyph];
      } else {
        wordGlyphMap[currentWordIndex]!.add(glyph);
      }
      lastRightBound = glyph.bounds.right;
    }

    // Create WordData list
    List<WordData> words = [];
    for (var entry in wordGlyphMap.entries) {
      words.add(WordData.fromGlyphArray(entry.key, entry.value));
    }

    double? fontSize;
    List<PdfFontStyle>? fontStyle;
    (fontSize, fontStyle) = _getFontAttributes(words);

    return LineData(
      lineIndex: lineIndex,
      text: words.map((w) => w.text).join(' '),
      fontSize: fontSize,
      fontStyle: fontStyle,
      bounds: _calculateBounds(glyphs),
      wordList: words,
    );
  }
}

class WordData {
  final String text;
  final double? fontSize;
  final Rect bounds;
  final List<PdfFontStyle>? fontStyle;
  final int wordIndex;
  final List<GlyphData> glyphList;

  WordData({
    required this.text,
    required this.fontSize,
    required this.bounds,
    required this.fontStyle,
    required this.glyphList,
    required this.wordIndex,
  });

  factory WordData.fromGlyphArray(int wordIndex, List<TextGlyph> glyphs) {
    double? fontSize;
    List<PdfFontStyle>? fontStyle;

    final glyphData = glyphs
        .asMap()
        .entries
        .map((e) => GlyphData.fromGlyph(e.key, e.value))
        .toList();

    (fontSize, fontStyle) = _getFontAttributes(glyphData);

    return WordData(
      wordIndex: wordIndex,
      text: glyphs.map((g) => g.text).join(),
      bounds: _calculateBounds(glyphs),
      fontSize: fontSize,
      fontStyle: fontStyle,
      glyphList: glyphData,
    );
  }
}

class GlyphData {
  final String text;
  final double fontSize;
  final Rect bounds;
  final List<PdfFontStyle> fontStyle;
  final int glyphIndex;

  GlyphData({
    required this.text,
    required this.fontSize,
    required this.bounds,
    required this.fontStyle,
    required this.glyphIndex,
  });

  factory GlyphData.fromGlyph(int glyphIndex, TextGlyph glyph) {
    return GlyphData(
      glyphIndex: glyphIndex,
      text: glyph.text,
      fontSize: glyph.fontSize,
      bounds: glyph.bounds,
      fontStyle: glyph.fontStyle,
    );
  }
}

Rect _calculateBounds(List<TextGlyph> glyphs) {
  if (glyphs.isEmpty) {
    return Rect.zero;
  }
  double left = glyphs.first.bounds.left;
  double top = glyphs.first.bounds.top;
  double right = glyphs.first.bounds.right;
  double bottom = glyphs.first.bounds.bottom;

  for (var glyph in glyphs) {
    if (glyph.bounds.left < left) {
      left = glyph.bounds.left;
    }
    if (glyph.bounds.top < top) {
      top = glyph.bounds.top;
    }
    if (glyph.bounds.right > right) {
      right = glyph.bounds.right;
    }
    if (glyph.bounds.bottom > bottom) {
      bottom = glyph.bounds.bottom;
    }
  }

  return Rect.fromLTRB(left, top, right, bottom);
}

(double?, List<PdfFontStyle>?) _getFontAttributes(List<dynamic> children) {
  if (children.isEmpty) {
    return (null, null);
  }

  bool allSameSize = children.every(
    (child) => child.fontSize == children.first.fontSize,
  );
  bool allSameStyle = children.every((child) {
    List<PdfFontStyle>? fontStyles = child.fontStyle;

    for (var style in fontStyles ?? []) {
      if (!children.every((c) => c.fontStyle?.contains(style) ?? false)) {
        return false;
      }
    }
    return true;
  });

  return (
    allSameSize ? children.first.fontSize : null,
    allSameStyle ? children.first.fontStyle : null,
  );
}
