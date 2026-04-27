import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/services/print_cache.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/widgets/ciphers/print/page_preview_painter.dart';
import 'package:cordeos/services/tokenization/build_service.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/services/tokenization/position_service.dart';
import 'package:cordeos/services/tokenization/tokenization_service.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:flutter/material.dart';

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
  final TextStyle lyricStyle;
  final TextStyle chordStyle;
  final TextStyle headerStyle;
  final TextStyle labelStyle;
  final double chordLyricSpacing;
  final double lineSpacing;
  final double letterSpacing;
  final double lineBreakSpacing;
  final double minChordSpacing;
  final double maxWidth;

  PrintingContext({
    required this.showHeader,
    required this.showRepeatSections,
    required this.showAnnotations,
    required this.showSongMap,
    required this.showSectionLabels,
    required this.showBpm,
    required this.showDuration,
    required this.lyricStyle,
    required this.chordStyle,
    required this.headerStyle,
    required this.labelStyle,
    required this.chordLyricSpacing,
    required this.lineSpacing,
    required this.letterSpacing,
    required this.lineBreakSpacing,
    required this.minChordSpacing,
    required this.maxWidth,
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
  String title;
  String author;
  String musicKey;
  int? bpm;
  Duration duration;
  List<String> codeSongMap;

  String bpmLabel;
  String songMapLabel;
  String durationLabel;

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

  /// ===== DATA CACHES =====
  final Map<String, Measurements> _tokenMeasurements = {};
  final Map<int, SectionPrintCache> _sectionCache = {};
  final HeaderData _headerData = HeaderData();

  /// ===== STATE SETTINGS =====
  // Filter Settings
  bool showHeader = true;
  bool showRepeatSections = true;
  bool showAnnotations = true;
  bool showSongMap = true;
  bool showSectionLabels = true;
  bool showBpm = true;
  bool showDuration = true;

  // Style settings
  String lyricFontFamily = 'OpenSans';
  double lyricFontSize = 12;
  Color lyricColor = Colors.black;
  TextStyle get lyricStyle => TextStyle(
    fontFamily: lyricFontFamily,
    fontSize: lyricFontSize,
    color: lyricColor,
  );

  String chordFontFamily = 'OpenSans';
  double chordFontSize = 10;
  Color chordColor = Colors.deepOrange;
  TextStyle get chordStyle => TextStyle(
    fontFamily: chordFontFamily,
    fontSize: chordFontSize,
    fontWeight: FontWeight.bold,
    color: chordColor,
  );

  String headerFontFamily = 'OpenSans';
  double headerFontSize = 12;
  Color headerColor = Colors.black;
  TextStyle get headerSyle => TextStyle(
    fontFamily: headerFontFamily,
    fontSize: headerFontSize,
    color: headerColor,
  );

  TextStyle get labelStyle => TextStyle(
    fontFamily: lyricFontFamily,
    fontStyle: FontStyle.italic,
    fontSize: lyricFontSize,
    fontWeight: FontWeight.bold,
    color: lyricColor,
  );

  // Layout settings
  double lineBreakSpacing = 0;
  double chordLyricSpacing = 0;
  double minChordSpacing = 5;
  double lineSpacing = 4;
  double letterSpacing = 0;

  // Page layout settings
  double horizontalMargin = 24;
  double verticalMargin = 24;
  double sectionSpacing = 16;
  double headerGap = 12;
  double columnGap = 16;
  int columnCount = 1;

  /// Initialize with stored settings
  Future<void> loadSettings() async {
    // Style Settings
    lyricFontSize = PrintCacheService.getLyricSize();
    lyricFontFamily = PrintCacheService.getLyricFontFamily();
    chordFontSize = PrintCacheService.getChordSize();
    chordFontFamily = PrintCacheService.getChordFontFamily();
    headerFontSize = PrintCacheService.getHeaderSize();
    headerFontFamily = PrintCacheService.getHeaderFontFamily();
    // Layout settings
    lineSpacing = PrintCacheService.getLineSpacing();
    lineBreakSpacing = PrintCacheService.getLineBreakSpacing();
    chordLyricSpacing = PrintCacheService.getChordLyricSpacing();
    minChordSpacing = PrintCacheService.getMinChordSpacing();
    letterSpacing = PrintCacheService.getLetterSpacing();
    showHeader = PrintCacheService.getShowHeader();
    showRepeatSections = PrintCacheService.getShowRepeatSections();
    showAnnotations = PrintCacheService.getShowAnnotations();
    showSongMap = PrintCacheService.getShowSongMap();
    showBpm = PrintCacheService.getShowBpm();
    showDuration = PrintCacheService.getShowDuration();
    showSectionLabels = PrintCacheService.getShowLabel();
    // Page layout settings
    horizontalMargin = PrintCacheService.getHorizontalMargin();
    verticalMargin = PrintCacheService.getVerticalMargin();
    sectionSpacing = PrintCacheService.getSectionSpacing();
    headerGap = PrintCacheService.getHeaderGap();
    columnGap = PrintCacheService.getColumnGap();
    columnCount = PrintCacheService.getColumnCount();
    notifyListeners();
  }

  void tokenize({
    required Cipher cipher,
    required Version version,
    required Map<int, Section> sections,
    required String Function(String) transposeChord,
    required BuildContext context,
  }) {
    _sectionCache.clear();
    final l10n = AppLocalizations.of(context)!;

    _headerData.title = cipher.title;
    _headerData.author = cipher.author;
    _headerData.musicKey = version.transposedKey ?? cipher.musicKey;
    _headerData.bpm = version.bpm;
    _headerData.duration = version.duration;
    _headerData.bpmLabel = l10n.bpm;
    _headerData.songMapLabel = l10n.songStructure;
    _headerData.durationLabel = l10n.duration;

    final types = <int, SectionType>{};
    for (var section in sections.values) {
      types[section.key] = section.sectionType;
    }
    final songMap = <String>[];
    final badgesData = getSectionBadges(types);
    for (final key in version.songStructure) {
      songMap.add(badgesData[key]!.code);
      final section = sections[key];
      if (section == null) {
        throw Exception(
          'Section with key $key not found for version ID: ${version.id}',
        );
      }

      final tokens = _tokenizer.tokenize(
        section.contentText,
        showLyrics: true,
        showChords: true,
        transposeChord: transposeChord,
      );

      final organized = _tokenizer.organize(tokens);

      if (!context.mounted) throw Exception('Context is not mounted');

      _sectionCache[key] = SectionPrintCache(
        key: key,
        code: badgesData[key]!.code,
        color: badgesData[key]!.color,
        label: section.sectionType.localizedLabel(context),
        type: section.sectionType,
        tokens: tokens,
        organized: organized,
      );
    }
    _headerData.codeSongMap = songMap;
  }

  Future<void> calculatePositions(double maxWidth) async {
    for (final cache in _sectionCache.values) {
      _measureTokens(
        tokens: cache.tokens,
        chordStyle: chordStyle,
        lyricStyle: lyricStyle,
        chordLyricSpacing: chordLyricSpacing,
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
        lineSpacing: lineSpacing,
        letterSpacing: letterSpacing,
        chordLyricSpacing: chordLyricSpacing,
        lineBreakSpacing: lineBreakSpacing,
        minChordSpacing: minChordSpacing,
      );
    }
  }

  PagePreviewSnapshot buildPreviewSnapshot(double maxWidth) {
    return PagePreviewSnapshot.build(
      sections: _sectionCache,
      builder: _builder,
      tokenMeasurements: _tokenMeasurements,
      header: _headerData,
      ctx: PrintingContext(
        showHeader: showHeader,
        showRepeatSections: showRepeatSections,
        showAnnotations: showAnnotations,
        showSongMap: showSongMap,
        showSectionLabels: showSectionLabels,
        showBpm: showBpm,
        showDuration: showDuration,
        lyricStyle: lyricStyle,
        chordStyle: chordStyle,
        headerStyle: headerSyle,
        labelStyle: labelStyle,
        chordLyricSpacing: chordLyricSpacing,
        lineSpacing: lineSpacing,
        letterSpacing: letterSpacing,
        lineBreakSpacing: lineBreakSpacing,
        minChordSpacing: minChordSpacing,
        maxWidth: maxWidth,
      ),
    );
  }

  /// Calculate the offsets of each section and in which page it sits, as well as the number of pages
  List<PageLayout> layoutPages(
    PagePreviewSnapshot snapshot,
    double pageHeight,
    double sectionWidth,
  ) {
    final pages = <PageLayout>[];
    final cursor = _LayoutCursor(
      headerHeight: snapshot.headerBlockHeight + headerGap,
      columnWidth: sectionWidth + columnGap,
    );

    final contentHeight = pageHeight - 2 * verticalMargin;

    final placements = <SectionPlacement>[];
    for (final model in snapshot.sectionModels.values) {
      final sectionBlockHeight =
          model.size.height + snapshot.sectionLabelHeight;
      if (sectionBlockHeight > contentHeight) {
        // TODO-Break sections bigger than space
        // for now skip
        debugPrint(
          "PRINTING PROVIDER - failed to layout section bigger than space available",
        );
        continue;
      }

      if (cursor.y + sectionBlockHeight > contentHeight) {
        final newPage = cursor.breakColumn(columnCount);

        if (newPage) {
          pages.add(PageLayout(placements: List.from(placements)));
          placements.clear();
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
      pages.add(PageLayout(placements: List.from(placements)));
      placements.clear();
    }

    return pages;
  }

  /// Measures every token in [tokens] and accumulates results into [measurements].
  /// Uses [putIfAbsent] so identical glyphs across sections are only computed once.
  void _measureTokens({
    required List<ContentToken> tokens,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double chordLyricSpacing,
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
        case TokenType.chordTarget:
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

  Future<void> setLyricFontSize(double size) async {
    lyricFontSize = size;
    await PrintCacheService.setLyricSize(size);
    notifyListeners();
  }

  Future<void> setLyricFontFamily(String family) async {
    lyricFontFamily = family;
    await PrintCacheService.setLyricFontFamily(family);
    notifyListeners();
  }

  Future<void> setChordFontSize(double size) async {
    chordFontSize = size;
    await PrintCacheService.setChordSize(size);
    notifyListeners();
  }

  Future<void> setChordFontFamily(String family) async {
    chordFontFamily = family;
    await PrintCacheService.setChordFontFamily(family);
    notifyListeners();
  }

  Future<void> setHeaderFontSize(double size) async {
    headerFontSize = size;
    await PrintCacheService.setHeaderSize(size);
    notifyListeners();
  }

  Future<void> setHeaderFontFamily(String family) async {
    headerFontFamily = family;
    await PrintCacheService.setHeaderFontFamily(family);
    notifyListeners();
  }

  // =========== SETTERS FOR LAYOUT SETTINGS =============

  Future<void> setLineSpacing(double spacing) async {
    lineSpacing = spacing;
    await PrintCacheService.setLineSpacing(spacing);
    notifyListeners();
  }

  Future<void> setLineBreakSpacing(double spacing) async {
    lineBreakSpacing = spacing;
    await PrintCacheService.setLineBreakSpacing(spacing);
    notifyListeners();
  }

  Future<void> setChordLyricSpacing(double spacing) async {
    chordLyricSpacing = spacing;
    await PrintCacheService.setChordLyricSpacing(spacing);
    notifyListeners();
  }

  Future<void> setMinChordSpacing(double spacing) async {
    minChordSpacing = spacing;
    await PrintCacheService.setMinChordSpacing(spacing);
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

  // =========== SETTERS FOR PAGE LAYOUT SETTINGS =============

  Future<void> setHorizontalMargin(double margin) async {
    horizontalMargin = margin;
    await PrintCacheService.setHorizontalMargin(margin);
    notifyListeners();
  }

  Future<void> setVerticalMargin(double margin) async {
    verticalMargin = margin;
    await PrintCacheService.setVerticalMargin(margin);
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
}
