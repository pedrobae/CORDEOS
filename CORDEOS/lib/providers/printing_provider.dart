import 'dart:typed_data';

import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/services/print_cache.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/utils/fonts.dart';
import 'package:cordeos/widgets/ciphers/print/page_preview_painter.dart';
import 'package:cordeos/services/tokenization/build_service.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/services/tokenization/position_service.dart';
import 'package:cordeos/services/tokenization/tokenization_service.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class _LayoutCursor {
  double x = 0;
  int pageIndex = 0;
  int columnIndex = 0;
  double headerHeight;
  double columnWidth;
  late double y = headerHeight;

  _LayoutCursor({required this.headerHeight, required this.columnWidth});

  // Returns whether a new page is needed
  bool breakColumn(int columnCount) {
    bool newPage = false;
    if (columnIndex + 1 == columnCount) {
      columnIndex = 0;
      pageIndex++;
      newPage = true;
    } else {
      columnIndex++;
    }
    x = columnIndex * columnWidth;
    if (pageIndex == 0) {
      y = headerHeight;
    } else {
      y = 0;
    }
    return newPage;
  }
}

class PrintingContext {
  final bool showHeader;
  final bool showRepeatSections;
  final bool showAnnotations;
  final bool showSongMap;
  final bool showSectionLabels;
  final bool showBpm;
  final bool showDuration;
  final bool showChords;
  final bool showLyrics;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;
  final TextStyle headerStyle;
  final TextStyle labelStyle;
  final double chordLyricSpacing;
  final double heightSpacing;
  static double minChordSpacing = 4;
  final double maxWidth;
  final double contentWidth;

  PrintingContext({
    required this.showHeader,
    required this.showRepeatSections,
    required this.showAnnotations,
    required this.showSongMap,
    required this.showSectionLabels,
    required this.showBpm,
    required this.showDuration,
    required this.showChords,
    required this.showLyrics,
    required this.lyricStyle,
    required this.chordStyle,
    required this.headerStyle,
    required this.labelStyle,
    required this.chordLyricSpacing,
    required this.heightSpacing,
    required this.maxWidth,
    required this.contentWidth,
  });
}

class SectionPrintCache {
  final int key;
  final SectionType type;
  final String code;
  final String label;
  final Color color;
  final List<ContentToken> tokens;
  final OrganizedTokens organized;
  TokenPositionMap? positions;

  SectionPrintCache({
    required this.key,
    required this.code,
    required this.color,
    required this.type,
    required this.tokens,
    required this.organized,
    required this.label,
  });
}

class HeaderData {
  final String title;
  final String author;
  final String musicKey;
  final int? bpm;
  final Duration duration;
  final String bpmLabel;
  final String songMapLabel;
  final String durationLabel;
  final List<String> codeSongMap;

  HeaderData({
    this.bpmLabel = 'BPM',
    this.songMapLabel = 'Song Map',
    this.durationLabel = 'Duration',
    this.title = '',
    this.author = '',
    this.musicKey = '',
    this.bpm = 0,
    this.duration = Duration.zero,
    this.codeSongMap = const [],
  });
}

class PrintingProvider extends ChangeNotifier {
  static const _tokenizer = TokenizationService();
  static const _builder = TokenizationBuilder();
  static const _positioner = PositionService();

  /// ===== VERSION DATA CACHES =====
  // String -> measurement
  final Map<String, Measurements> _tokenMeasurements = {};

  // contentID -> PlaylistItem
  final List<PlaylistItem> _itemsCache = [];

  // versionID -> sectionID -> cache
  final Map<int, Map<int, SectionPrintCache>> _versionsSectionCache = {};
  // versionID -> songMap
  final Map<int, List<int>> _songMaps = {};
  // versionID -> headerData
  final Map<int, HeaderData> _headersData = {};

  // flowID -> FlowItem
  final Map<int, FlowItem> _flowCache = {};

  /// ===== STATE SETTINGS =====
  // Filter Settings
  bool showHeader = true;
  bool showRepeatSections = true;
  bool showAnnotations = true;
  bool showSongMap = true;
  bool showSectionLabels = true;
  bool showBpm = true;
  bool showDuration = true;
  bool showChords = true;
  bool showLyrics = true;

  // Style settings
  String fontFamily = 'OpenSans';
  double fontSize = 12;
  Color lyricColor = Colors.black;
  Color chordColor = Colors.deepOrange;
  Color headerColor = Colors.black;

  TextStyle get lyricStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    color: lyricColor,
    height: 1,
  );

  TextStyle get chordStyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    height: 1,
    color: chordColor,
  );

  TextStyle get headerSyle => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize * 0.8,
    height: 1,
    color: headerColor,
  );

  TextStyle get labelStyle => TextStyle(
    fontFamily: fontFamily,
    fontStyle: FontStyle.italic,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    height: 1,
    color: lyricColor,
  );

  // Layout settings
  double heightSpacing = 1;
  double minChordSpacing = 5;
  double letterSpacing = 0;

  // Page layout settings
  double margin = 24;
  double sectionSpacing = 16;
  double headerGap = 12;
  double columnGap = 16;
  int columnCount = 1;

  /// Initialize with stored settings
  Future<void> loadSettings() async {
    // Style Settings
    fontSize = PrintCacheService.getSize();
    fontFamily = PrintCacheService.getFontFamily();
    // Layout settings
    heightSpacing = PrintCacheService.getHeightSpacing();
    letterSpacing = PrintCacheService.getLetterSpacing();
    showHeader = PrintCacheService.getShowHeader();
    showRepeatSections = PrintCacheService.getShowRepeatSections();
    showAnnotations = PrintCacheService.getShowAnnotations();
    showSongMap = PrintCacheService.getShowSongMap();
    showBpm = PrintCacheService.getShowBpm();
    showDuration = PrintCacheService.getShowDuration();
    showSectionLabels = PrintCacheService.getShowLabel();
    showChords = PrintCacheService.getShowChords();
    showLyrics = PrintCacheService.getShowLyrics();
    // Page layout settings
    margin = PrintCacheService.getMargin();
    sectionSpacing = PrintCacheService.getSectionSpacing();
    headerGap = PrintCacheService.getHeaderGap();
    columnGap = PrintCacheService.getColumnGap();
    columnCount = PrintCacheService.getColumnCount();
    notifyListeners();
  }

  void tokenize({
    required List<PlaylistItem> items,
    required Map<int, Cipher> ciphers,
    required Map<int, Version> versions,
    required Map<int, FlowItem> flowItems,
    required Map<int, Map<int, Section>> versionsSections,
    required Map<int, String Function(String)> versionsTransposeChords,
    required BuildContext context,
  }) {
    clearCache();

    final l10n = AppLocalizations.of(context)!;

    _itemsCache.addAll(items);
    _flowCache.addAll(flowItems);

    for (final item in items) {
      switch (item.type) {
        case PlaylistItemType.version:
          final version = versions[item.contentId!];
          final cipher = ciphers[item.contentId!];
          final sections = versionsSections[item.contentId!];
          final transposeChord = versionsTransposeChords[item.contentId!];

          if (cipher == null ||
              sections == null ||
              transposeChord == null ||
              version == null) {
            debugPrint(
              "Couldnt find Cipher, Version, Sections, or TransposeChord for version ${item.contentId!}",
            );
            continue;
          }

          _songMaps[version.id!] = version.songStructure;

          _versionsSectionCache[version.id!] = {};
          final types = <int, SectionType>{};
          for (var section in sections.values) {
            types[section.key] = section.sectionType;
          }
          final badgesData = getSectionBadges(types);
          _headersData[version.id!] = HeaderData(
            title: cipher.title,
            author: cipher.author,
            musicKey: version.transposedKey ?? cipher.musicKey,
            bpm: version.bpm,
            duration: version.duration,
            songMapLabel: l10n.songStructure,
            bpmLabel: l10n.bpm,
            durationLabel: l10n.duration,
            codeSongMap: version.songStructure
                .map((int key) => badgesData[key]!.code)
                .toList(),
          );
          for (final sectionKey in version.songStructure) {
            final section = sections[sectionKey];
            if (section == null) {
              throw Exception(
                'Section with key $sectionKey not found for version ID: ${version.id}',
              );
            }

            final tokens = _tokenizer.tokenize(
              section.contentText,
              showLyrics: showLyrics,
              showChords: showChords,
              transposeChord: transposeChord,
            );

            final organized = _tokenizer.organize(tokens);

            if (!context.mounted) throw Exception('Context is not mounted');

            _versionsSectionCache[version.id!]![sectionKey] = SectionPrintCache(
              key: sectionKey,
              code: badgesData[sectionKey]!.code,
              color: badgesData[sectionKey]!.color,
              label: section.sectionType.localizedLabel(context),
              type: section.sectionType,
              tokens: tokens,
              organized: organized,
            );
          }
        case PlaylistItemType.flowItem:
          // No flow item tokenization
          break;
      }
    }
  }

  Future<void> calculatePositions(double maxWidth) async {
    for (final sectionCache in _versionsSectionCache.values) {
      for (final cache in sectionCache.values) {
        _measureTokens(
          tokens: cache.tokens,
          chordStyle: chordStyle,
          lyricStyle: lyricStyle,
          measurements: _tokenMeasurements,
        );

        final lyricHeight = _builder
            .measureText(text: 'SampleText', style: lyricStyle)
            .height;
        final chordHeight = _builder
            .measureText(text: 'SampleText', style: chordStyle)
            .height;

        cache.positions = _positioner.calculateTokenPositions(
          organizedTokens: cache.organized,
          measurements: _tokenMeasurements,
          lyricStyle: lyricStyle,
          chordStyle: chordStyle,
          maxWidth: maxWidth,
          chordHeight: chordHeight,
          lyricHeight: lyricHeight,
          isEditMode: false,
          heightSpacing: heightSpacing,
          letterSpacing: letterSpacing,
          minChordSpacing: minChordSpacing,
          showChords: showChords,
          showLyrics: showLyrics,
        );
      }
    }
  }

  List<PrintPreviewSnapshot> buildPreviewSnapshot(double maxWidth) {
    final snapshots = <PrintPreviewSnapshot>[];
    final ctx = PrintingContext(
      showHeader: showHeader,
      showRepeatSections: showRepeatSections,
      showAnnotations: showAnnotations,
      showSongMap: showSongMap,
      showSectionLabels: showSectionLabels,
      showBpm: showBpm,
      showDuration: showDuration,
      showChords: showChords,
      showLyrics: showLyrics,
      lyricStyle: lyricStyle,
      chordStyle: chordStyle,
      headerStyle: headerSyle,
      labelStyle: labelStyle,
      chordLyricSpacing: heightSpacing,
      heightSpacing: heightSpacing,
      maxWidth: maxWidth,
      contentWidth: (maxWidth * columnCount) + ((columnCount - 1) * columnGap),
    );
    for (final item in _itemsCache) {
      switch (item.type) {
        case PlaylistItemType.version:
          snapshots.add(
            PrintPreviewSnapshot(
              type: item.type,
              songSnapshot: SongPPS.build(
                songMap: _songMaps[item.contentId]!,
                sections: _versionsSectionCache[item.contentId]!,
                builder: _builder,
                tokenMeasurements: _tokenMeasurements,
                headerData: _headersData[item.contentId]!,
                ctx: ctx,
              ),
            ),
          );
          break;
        case PlaylistItemType.flowItem:
          snapshots.add(
            PrintPreviewSnapshot(
              type: item.type,
              flowSnapshot: FlowPPS.build(
                flow: _flowCache[item.contentId]!,
                ctx: ctx,
              ),
            ),
          );
          break;
      }
    }
    return snapshots;
  }

  /// Calculate the offsets of each section and in which page it sits, as well as the number of pages
  List<PageLayout> layoutPages(
    List<PrintPreviewSnapshot> snapshots,
    double pageHeight,
    double sectionWidth,
  ) {
    final pages = <PageLayout>[];
    int snapIdx = 0;
    for (final snapshot in snapshots) {
      switch (snapshot.type) {
        case PlaylistItemType.version:
          final songSnapshot = snapshot.songSnapshot!;
          final cursor = _LayoutCursor(
            headerHeight: showHeader
                ? songSnapshot.headerBlockHeight + headerGap
                : 0,
            columnWidth: sectionWidth + columnGap,
          );

          final contentHeight = pageHeight - 2 * margin;

          final placements = <SectionPlacement>[];
          final seenKeys = <int>{};
          bool firstPage = true;
          for (final key in songSnapshot.songMap) {
            if (seenKeys.contains(key) && !showRepeatSections) {
              continue;
            }
            seenKeys.add(key);

            final model = songSnapshot.sectionModels[key]!;
            final sectionBlockHeight =
                model.size.height +
                (showSectionLabels ? songSnapshot.sectionLabelHeight : 0);

            if (sectionBlockHeight > contentHeight) {
              // TODO-Break sections bigger than space
              // for now skip
              debugPrint("PRINTING PROVIDER - failed to layout big section");
            }

            if (cursor.y + sectionBlockHeight > contentHeight) {
              final newPage = cursor.breakColumn(columnCount);

              if (newPage) {
                pages.add(
                  PageLayout(
                    snapshotIndex: snapIdx,
                    isFlow: false,
                    songPageLayout: SongPageLayout(
                      placements: List.from(placements),
                      showHeader: firstPage,
                    ),
                  ),
                );
                placements.clear();
                firstPage = false;
              }
            }

            placements.add(
              SectionPlacement(
                sectionKey: model.key,
                pageIndex: cursor.pageIndex,
                columnIndex: cursor.columnIndex,
                xOffset: cursor.x,
                yOffset: cursor.y,
              ),
            );

            cursor.y += sectionBlockHeight + sectionSpacing;
          }

          if (placements.isNotEmpty) {
            pages.add(
              PageLayout(
                isFlow: false,
                snapshotIndex: snapIdx,
                songPageLayout: SongPageLayout(
                  placements: List.from(placements),
                ),
              ),
            );
            placements.clear();
          }
          break;
        case PlaylistItemType.flowItem:
          pages.add(
            PageLayout(
              isFlow: true,
              songPageLayout: null,
              snapshotIndex: snapIdx,
            ),
          );
          break;
      }
      snapIdx++;
    }

    return pages;
  }

  /// Measures every token in [tokens] and accumulates results into [measurements].
  /// Uses [putIfAbsent] so identical glyphs across sections are only computed once.
  void _measureTokens({
    required List<ContentToken> tokens,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required Map<String, Measurements> measurements,
  }) {
    for (final token in tokens) {
      switch (token.type) {
        case TokenType.chord:
          final key = measurementKey(token.text, chordStyle);
          measurements.putIfAbsent(
            key,
            () => _builder.measureText(text: token.text, style: chordStyle),
          );
          break;

        case TokenType.space:
        case TokenType.lyric:
          final key = measurementKey(token.text, lyricStyle);
          measurements.putIfAbsent(
            key,
            () => _builder.measureText(text: token.text, style: lyricStyle),
          );
          break;

        case TokenType.preSeparator:
        case TokenType.postSeparator:
        case TokenType.preChordTarget:
        case TokenType.postChordTarget:
          // Targets are not shown on the PDF
          break;
        case TokenType.underline:
        case TokenType.newline:
          // Computed dynamically during positioning — nothing to pre-measure.
          break;
      }
    }
  }

  // =========== SETTERS FOR STYLE SETTINGS =============

  Future<void> setFontSize(double size) async {
    fontSize = size;
    await PrintCacheService.setSize(size);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    fontFamily = family;
    await PrintCacheService.setFontFamily(family);
    notifyListeners();
  }

  // =========== SETTERS FOR LAYOUT SETTINGS =============

  Future<void> setHeightSpacing(double spacing) async {
    heightSpacing = spacing;
    await PrintCacheService.setHeightSpacing(spacing);
    notifyListeners();
  }

  Future<void> setLetterSpacing(double spacing) async {
    letterSpacing = spacing;
    await PrintCacheService.setLetterSpacing(spacing);
    notifyListeners();
  }

  // =========== SETTERS FOR FILTER SETTINGS =============

  Future<void> toggleHeader() async {
    showHeader = !showHeader;
    await PrintCacheService.setShowHeader(showHeader);
    notifyListeners();
  }

  Future<void> toggleRepeatSections() async {
    showRepeatSections = !showRepeatSections;
    await PrintCacheService.setShowRepeatSections(showRepeatSections);
    notifyListeners();
  }

  Future<void> toggleAnnotations() async {
    showAnnotations = !showAnnotations;
    await PrintCacheService.setShowAnnotations(showAnnotations);
    notifyListeners();
  }

  Future<void> toggleSongMap() async {
    showSongMap = !showSongMap;
    await PrintCacheService.setShowSongMap(showSongMap);
    notifyListeners();
  }

  Future<void> toggleSectionLabels() async {
    showSectionLabels = !showSectionLabels;
    await PrintCacheService.setShowLabel(showSectionLabels);
    notifyListeners();
  }

  Future<void> toggleBpm() async {
    showBpm = !showBpm;
    await PrintCacheService.setShowBpm(showBpm);
    notifyListeners();
  }

  Future<void> toggleDuration() async {
    showDuration = !showDuration;
    await PrintCacheService.setShowDuration(showDuration);
    notifyListeners();
  }

  Future<void> toggleChords() async {
    showChords = !showChords;
    await PrintCacheService.setShowChords(showChords);
    notifyListeners();
  }

  Future<void> toggleLyrics() async {
    showLyrics = !showLyrics;
    await PrintCacheService.setShowLyrics(showChords);
    notifyListeners();
  }

  // =========== SETTERS FOR PAGE LAYOUT SETTINGS =============

  Future<void> setMargin(double margin) async {
    this.margin = margin;
    await PrintCacheService.setMargin(margin);
    notifyListeners();
  }

  Future<void> setSectionSpacing(double spacing) async {
    sectionSpacing = spacing;
    await PrintCacheService.setSectionSpacing(spacing);
    notifyListeners();
  }

  Future<void> setHeaderGap(double gap) async {
    headerGap = gap;
    await PrintCacheService.setHeaderGap(gap);
    notifyListeners();
  }

  Future<void> setColumnGap(double gap) async {
    columnGap = gap;
    await PrintCacheService.setColumnGap(gap);
    notifyListeners();
  }

  Future<void> toggleColumnCount() async {
    columnCount = (columnCount == 1) ? 2 : 1;
    await PrintCacheService.setColumnCount(columnCount);
    notifyListeners();
  }

  Future<Uint8List> generatePDF(
    List<PageLayout> pages,
    List<PrintPreviewSnapshot> snapshots,
    double pageWidth,
  ) async {
    final document = PdfDocument();

    final standardPageSize = PdfPageSettings().width; // or use document default
    final ratio = standardPageSize / pageWidth;

    document.pageSettings.margins = (PdfMargins()..all = margin * ratio);

    // Pre-load all fonts needed for this PDF
    final fontCache = <String, PdfFont>{};
    await _preloadFonts(snapshots, fontCache, ratio);

    for (int pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final layout = pages[pageIdx];
      final snapshot = snapshots[layout.snapshotIndex];
      final page = document.pages.add();

      switch (snapshot.type) {
        case PlaylistItemType.version:
          final songLayout = layout.songPageLayout!;
          final songSnapshot = snapshot.songSnapshot!;
          double currentY = 0;
          // DRAW HEADER (only on first page)
          if (songLayout.showHeader && songSnapshot.headerBlockHeight > 0) {
            for (final instruction in songSnapshot.headerInstructions) {
              final scaledX = instruction.offset.dx * ratio;
              final scaledY = currentY + (instruction.offset.dy * ratio);

              _drawHeaderLine(
                page.graphics,
                instruction,
                scaledX,
                scaledY,
                ratio,
                fontCache,
              );
            }
            currentY +=
                songSnapshot.headerBlockHeight * ratio + headerGap * ratio;
          }

          // DRAW SECTIONS
          for (final placement in songLayout.placements) {
            final model = songSnapshot.sectionModels[placement.sectionKey]!;

            // Calculate section position with margins
            // Note: placement.yOffset already includes header height on first page
            final sectionX = placement.xOffset * ratio;
            final sectionY = placement.yOffset * ratio;

            // Draw section label and badge if needed
            final badge = songSnapshot.badgeModels[placement.sectionKey];
            final label =
                songSnapshot.sectionLabelPainters[placement.sectionKey];

            if (badge != null && label != null && showSectionLabels) {
              _drawSectionBadge(
                page.graphics,
                badge,
                label,
                sectionX,
                sectionY,
                ratio,
                fontCache,
              );
            }

            // Draw section content (text instructions and underlines)
            _drawSectionContent(
              page.graphics,
              model,
              sectionX,
              sectionY +
                  (songSnapshot.sectionLabelHeight * ratio) +
                  (4 * ratio),
              ratio,
              fontCache,
            );
          }
        case PlaylistItemType.flowItem:
          final flowSnapshot = snapshot.flowSnapshot!;

          // DRAW FLOW HEADER
          // Get font from cache
          final headerFont =
              fontCache[_getKey(flowSnapshot.headerStyle, ratio)];
          if (headerFont == null)
            throw Exception("Couldnt find header font on cache");
          page.graphics.drawString(
            flowSnapshot.headerPainter.plainText,
            headerFont,
          );

          // DRAW FLOW CONTENT
          // Get font from cache
          final contentFont =
              fontCache[_getKey(flowSnapshot.contentStyle, ratio)];
          if (contentFont == null)
            throw Exception("Couldnt find header font on cache");
          page.graphics.drawString(
            flowSnapshot.contentPainter.plainText,
            contentFont,
          );
      }
    }

    return await document.saveAsBytes();
  }

  /// Pre-load all fonts used in the snapshot to cache them
  Future<void> _preloadFonts(
    List<PrintPreviewSnapshot> snapshots,
    Map<String, PdfFont> fontCache,
    double ratio,
  ) async {
    final fontKeys = <String>{};
    for (final snapshot in snapshots) {
      switch (snapshot.type) {
        case PlaylistItemType.version:
          final songSnap = snapshot.songSnapshot!;
          // Collect fonts from header
          for (final instruction in songSnap.headerInstructions) {
            fontKeys.add(_getKey(instruction.style, ratio));
          }
          // Collect fonts from sections
          for (final model in songSnap.sectionModels.values) {
            for (final instruction in model.textInstructions) {
              fontKeys.add(_getKey(instruction.style, ratio));
            }
          }
          for (final model in songSnap.badgeModels.values) {
            fontKeys.add(_getKey(model.style, ratio));
          }
          for (final model in songSnap.sectionLabelPainters.values) {
            fontKeys.add(_getKey(model.style, ratio));
          }
          break;
        case PlaylistItemType.flowItem:
          final flowSnap = snapshot.flowSnapshot!;
          fontKeys.add(_getKey(flowSnap.headerStyle, ratio));
          fontKeys.add(_getKey(flowSnap.contentStyle, ratio));
      }
    }

    // Load all fonts
    for (final key in fontKeys) {
      final splitKey = key.split('_');
      try {
        final font = await getPdfFont(
          splitKey[0],
          double.tryParse(splitKey[3]) ?? 0,
          isBold: splitKey[1] == 'true',
          isItalic: splitKey[2] == 'true',
        );
        fontCache[key] = font;
      } catch (e) {
        debugPrint('Failed to preload font ${splitKey[0]}: $e');
      }
    }
  }

  /// Draw a single text instruction with proper styling
  void _drawHeaderLine(
    PdfGraphics graphics,
    TextPaintInstruction i,
    double x,
    double y,
    double ratio,
    Map<String, PdfFont> fontCache,
  ) {
    final ratioedSize = i.style.fontSize! * ratio;
    final fontName = i.style.fontFamily;
    final isBold = i.style.fontWeight == FontWeight.bold;
    final isItalic = i.style.fontStyle == FontStyle.italic;

    // Get font from cache
    final cacheKey = '${fontName}_${isBold}_${isItalic}_$ratioedSize';
    final pdfFont = fontCache[cacheKey];

    if (pdfFont == null) throw Exception("Couldnt find header font on cache");

    // Set text color if specified, default to black if not
    graphics.drawString(
      i.painter.plainText,
      pdfFont,
      brush: PdfSolidBrush(_colorToPdfColor(i.style.color ?? Colors.black)),
      bounds: Rect.fromLTWH(x, y, double.maxFinite, ratioedSize * 2),
    );
  }

  /// Draw section badge with label
  void _drawSectionBadge(
    PdfGraphics graphics,
    BadgePaintModel badge,
    LabelPaintModel label,
    double x,
    double y,
    double ratio,
    Map<String, PdfFont> fontCache,
  ) {
    // Draw badge background (rounded rectangle)
    final badgeWidth = (badge.textPainter.width + 8) * ratio;
    final badgeHeight = (badge.textPainter.height + 4) * ratio;
    final cornerRadius = 4 * ratio;

    // Create a rounded rectangle path
    final pdfPath = PdfPath();
    pdfPath.addLine(
      Offset(x + cornerRadius, y),
      Offset(x + badgeWidth - cornerRadius, y),
    );
    pdfPath.addArc(
      Rect.fromLTWH(
        x + badgeWidth - cornerRadius * 2,
        y,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      270,
      90,
    );
    pdfPath.addLine(
      Offset(x + badgeWidth, y + cornerRadius),
      Offset(x + badgeWidth, y + badgeHeight - cornerRadius),
    );
    pdfPath.addArc(
      Rect.fromLTWH(
        x + badgeWidth - cornerRadius * 2,
        y + badgeHeight - cornerRadius * 2,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      0,
      90,
    );
    pdfPath.addLine(
      Offset(x + cornerRadius, y + badgeHeight),
      Offset(x + badgeWidth - cornerRadius, y + badgeHeight),
    );
    pdfPath.addArc(
      Rect.fromLTWH(
        x,
        y + badgeHeight - cornerRadius * 2,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      90,
      90,
    );
    pdfPath.addLine(
      Offset(x, y + cornerRadius),
      Offset(x, y + badgeHeight - cornerRadius),
    );
    pdfPath.addArc(
      Rect.fromLTWH(x, y, cornerRadius * 2, cornerRadius * 2),
      180,
      90,
    );
    pdfPath.closeFigure();

    graphics.drawPath(
      pdfPath,
      brush: PdfSolidBrush(_colorToPdfColor(badge.color)),
    );

    // Draw badge text
    final badgeFontSize = (badge.style.fontSize ?? fontSize) * ratio;
    final badgeFontName = badge.style.fontFamily ?? fontFamily;
    final badgeIsBold = badge.style.fontWeight == FontWeight.bold;
    final badgeIsItalic = badge.style.fontStyle == FontStyle.italic;
    final badgeCacheKey =
        '${badgeFontName}_${badgeIsBold}_${badgeIsItalic}_$badgeFontSize';
    final badgeFont = fontCache[badgeCacheKey];

    if (badgeFont == null) throw Exception("Couldnt find badge font in cache");

    graphics.drawString(
      badge.textPainter.plainText,
      badgeFont,
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(x + (4 * ratio), y, badgeWidth, badgeFontSize * 2),
    );

    // Draw label text
    final style = label.style;
    final labelFontSize = style.fontSize! * ratio;
    final fontName = style.fontFamily!;
    final isBold = style.fontWeight == FontWeight.bold;
    final isItalic = style.fontStyle == FontStyle.italic;

    final cacheKey = '${fontName}_${isBold}_${isItalic}_$labelFontSize';
    final labelFont = fontCache[cacheKey];

    if (labelFont == null) throw Exception("Couldnt find label font in cache");

    graphics.drawString(
      label.textPainter.plainText,
      labelFont,
      brush: PdfSolidBrush(_colorToPdfColor(style.color ?? Colors.black)),
      bounds: Rect.fromLTWH(
        x + badgeWidth + (12 * ratio),
        y + (2 * ratio),
        double.maxFinite,
        labelFontSize * 2,
      ),
    );
  }

  /// Draw section content (chords, lyrics, underlines)
  void _drawSectionContent(
    PdfGraphics graphics,
    SectionPaintModel model,
    double baseX,
    double baseY,
    double ratio,
    Map<String, PdfFont> fontCache,
  ) {
    // Draw text instructions (chords and lyrics)
    for (final inst in model.textInstructions) {
      final ratioedSize = inst.style.fontSize! * ratio;
      final fontName = inst.style.fontFamily;
      final isBold = inst.style.fontWeight == FontWeight.bold;
      final isItalic = inst.style.fontStyle == FontStyle.italic;

      // Get font from cache
      final cacheKey = '${fontName}_${isBold}_${isItalic}_$ratioedSize';
      final pdfFont = fontCache[cacheKey];

      if (pdfFont == null)
        throw Exception("Couldn't find content font in cache");

      final textX = baseX + (inst.offset.dx * ratio);
      final textY = baseY + (inst.offset.dy * ratio);

      graphics.drawString(
        inst.painter.plainText,
        pdfFont,
        brush: PdfSolidBrush(
          _colorToPdfColor(inst.style.color ?? Colors.black),
        ),
        bounds: Rect.fromLTWH(textX, textY, double.maxFinite, ratioedSize * 2),
      );
    }

    // Draw underlines
    for (final underline in model.underlines) {
      final underlineX1 = baseX + (underline.offset.dx * ratio);
      final underlineY = baseY + (underline.offset.dy * ratio);
      final underlineX2 = underlineX1 + (underline.width * ratio);

      graphics.drawLine(
        PdfPen(_colorToPdfColor(model.underlineColor), width: 1 * ratio),
        Offset(underlineX1, underlineY),
        Offset(underlineX2, underlineY),
      );
    }
  }

  /// Convert Flutter Color to PDF Color
  PdfColor _colorToPdfColor(Color color) {
    return PdfColor(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );
  }

  void clearCache() {
    _itemsCache.clear();
    _flowCache.clear();
    _versionsSectionCache.clear();
    _songMaps.clear();
    _headersData.clear();
  }

  String _getKey(TextStyle style, double ratio) {
    final fontName = style.fontFamily ?? 'OpenSans';
    final isBold = style.fontWeight == FontWeight.bold;
    final isItalic = style.fontStyle == FontStyle.italic;
    final size = style.fontSize! * ratio;

    return '${fontName}_${isBold}_${isItalic}_${size}';
  }
}
