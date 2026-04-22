import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/dtos/song_pdf_dto.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/widgets/ciphers/print/page_preview_painter.dart';
import 'package:flutter/material.dart';

// A4 dimensions in logical pixels at 72 DPI equivalents
const double _kPageWidth = 595.0;
const double _kPageHeight = 842.0;
const double _kHorizontalMargin = 40.0;
const double _kTopMargin = 40.0;
const double _kContentWidth = _kPageWidth - 2 * _kHorizontalMargin;
const double _kColumnGap = 16.0;
const double _kSectionSpacing = 24.0;

class PrintPreviewScreen extends StatefulWidget {
  final int versionID;

  const PrintPreviewScreen({super.key, required this.versionID});

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  final _provider = PrintingProvider();

  // Print settings
  int _columnCount = 1;
  bool _showMetadata = true;
  bool _showRepeatSections = true;
  bool _showAnnotations = true;
  bool _showSongMap = true;
  bool _showSectionLabels = true;
  bool _showBpm = true;
  bool _showDuration = true;

  // Built state
  SongPdfDto? _dto;
  PagePreviewSnapshot? _snapshot;
  bool _isBuilding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuild());
  }

  // ─── Options ─────────────────────────────────────────────────────────────

  double get _layoutWidth =>
      _columnCount == 1 ? _kContentWidth : (_kContentWidth - _kColumnGap) / 2;

  TextStyle get _lyricStyle => const TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 11,
    color: Colors.black,
  );

  TextStyle get _chordStyle => const TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.deepOrange,
  );

  TextStyle get _metadataStyle => const TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 11,
    color: Colors.black,
  );

  TextStyle get _labelStyle => const TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Colors.blueGrey,
  );

  SongPdfBuildOptions get _buildOptions => SongPdfBuildOptions(
    pageContentWidth: _kContentWidth,
    layoutWidth: _layoutWidth,
    lyricStyle: _lyricStyle,
    chordStyle: _chordStyle,
    metadataStyle: _metadataStyle,
    sectionLabelStyle: _labelStyle,
    lineBreakSpacing: 0,
    chordLyricSpacing: 0,
    minChordSpacing: 5,
  );

  SongPreviewDisplayOptions _displayOptions(SongPdfDto dto) {
    final l10n = AppLocalizations.of(context)!;
    return SongPreviewDisplayOptions(
      showSongMap: _showSongMap,
      showBpm: _showBpm,
      showDuration: _showDuration,
      songMapLabel: l10n.songStructure,
      bpmLabel: l10n.bpm,
      durationLabel: l10n.duration,
      labelData: _buildSectionLabels(dto),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  Future<void> _rebuild() async {
    if (!mounted) return;
    setState(() {
      _isBuilding = true;
      _error = null;
    });

    try {
      final dto = await _provider.buildSongPdfDto(
        versionID: widget.versionID,
        options: _buildOptions,
      );

      final snapshot = _provider.buildPreviewSnapshot(
        dto: dto,
        displayOptions: _displayOptions(dto),
      );

      if (mounted) {
        setState(() {
          _dto = dto;
          _snapshot = snapshot;
          _isBuilding = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isBuilding = false;
        });
      }
    }
  }

  /// Rebuilds only the snapshot from the cached DTO — no database round-trip.
  /// Call this when display options change (BPM, song map, duration, section labels).
  void _rebuildSnapshot() {
    final dto = _dto;
    if (dto == null) return;
    final snapshot = _provider.buildPreviewSnapshot(
      dto: dto,
      displayOptions: _displayOptions(dto),
    );
    setState(() => _snapshot = snapshot);
  }

  // ─── Toggles (visual-only — no DTO rebuild needed) ───────────────────────

  void _toggleMetadata() => setState(() => _showMetadata = !_showMetadata);
  void _toggleRepeatSections() =>
      setState(() => _showRepeatSections = !_showRepeatSections);
  void _toggleAnnotations() =>
      setState(() => _showAnnotations = !_showAnnotations);

  // Column count requires a layout rebuild since it changes token wrapping
  void _setColumns(int count) {
    if (count == _columnCount) return;
    setState(() => _columnCount = count);
    _rebuild();
  }

  // ─── Toggles ─────────────────────────────────────────────────────────────

  // These affect the snapshot's metadata/label content — require snapshot rebuild.
  void _toggleSongMap() {
    _showSongMap = !_showSongMap;
    _rebuildSnapshot();
  }

  void _toggleSectionLabels() {
    _showSectionLabels = !_showSectionLabels;
    _rebuildSnapshot();
  }

  void _toggleBpm() {
    _showBpm = !_showBpm;
    _rebuildSnapshot();
  }

  void _toggleDuration() {
    _showDuration = !_showDuration;
    _rebuildSnapshot();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(l10n.printPreview, style: textTheme.titleMedium),
        leading: BackButton(
          color: colorScheme.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // TODO: trigger actual PDF generation + save/share
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: l10n.printPreview,
            onPressed: _dto == null ? null : () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlBar(l10n, colorScheme, textTheme),
          Expanded(child: _buildPreviewArea(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildControlBar(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      color: colorScheme.surface,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        spacing: 8,
        children: [
          Wrap(
            runSpacing: 8,
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ToggleChip(
                label: l10n.repeatSections,
                active: _showRepeatSections,
                onTap: _toggleRepeatSections,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _ToggleChip(
                label: l10n.printMetadata,
                active: _showMetadata,
                onTap: _toggleMetadata,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _ToggleChip(
                label: l10n.annotations,
                active: _showAnnotations,
                onTap: _toggleAnnotations,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _ToggleChip(
                label: l10n.songStructure,
                active: _showSongMap,
                onTap: _toggleSongMap,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _ToggleChip(
                label: l10n.sectionLabels,
                active: _showSectionLabels,
                onTap: _toggleSectionLabels,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _ToggleChip(
                label: l10n.bpm,
                active: _showBpm,
                onTap: _toggleBpm,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _ToggleChip(
                label: l10n.duration,
                active: _showDuration,
                onTap: _toggleDuration,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.printColumns, style: textTheme.labelMedium),
              const SizedBox(width: 8),
              _ColumnSelector(
                current: _columnCount,
                onSelect: _setColumns,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(ColorScheme colorScheme) {
    if (_isBuilding) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: TextStyle(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_dto == null || _snapshot == null) {
      return const SizedBox.shrink();
    }

    final layout = PagePreviewLayout.build(
      dto: _dto!,
      snapshot: _snapshot!,
      showMetadata: _showMetadata,
      showRepeatSections: _showRepeatSections,
      showAnnotations: _showAnnotations,
      showSectionLabels: _showSectionLabels,
      columnCount: _columnCount,
      pageHeight: _kPageHeight,
      topMargin: _kTopMargin,
      columnGap: _kColumnGap,
      sectionSpacing: _kSectionSpacing,
      metadataGap: 12,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.clamp(0.0, 600.0);
            final scale = availableWidth / _kPageWidth;
            final displayHeight = _kPageHeight * scale;

            return Column(
              spacing: 16,
              children: [
                for (
                  int pageIndex = 0;
                  pageIndex < layout.pageCount;
                  pageIndex++
                )
                  SizedBox(
                    width: availableWidth,
                    height: displayHeight,
                    child: CustomPaint(
                      painter: PagePreviewPainter(
                        snapshot: _snapshot!,
                        dto: _dto!,
                        layout: layout,
                        pageIndex: pageIndex,
                        showMetadata: _showMetadata,
                        showRepeatSections: _showRepeatSections,
                        showAnnotations: _showAnnotations,
                        pageWidth: _kPageWidth,
                        pageHeight: _kPageHeight,
                        horizontalMargin: _kHorizontalMargin,
                        topMargin: _kTopMargin,
                        columnGap: _kColumnGap,
                        sectionSpacing: _kSectionSpacing,
                        pageColor: Colors.white,
                        shadowColor: Colors.black26,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<int, SectionLabelData> _buildSectionLabels(SongPdfDto dto) {
    final labelsData = <int, SectionLabelData>{};
    for (final entry in dto.badgesData.entries) {
      final key = entry.key;
      final badgeData = entry.value;

      labelsData[key] = SectionLabelData(
        type: badgeData.type,
        code: badgeData.code,
        localizedLabel: badgeData.type.localizedLabel(context),
      );
    }

    return labelsData;
  }
}

// ─── Small reusable control widgets ──────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? colorScheme.onSurface
              : colorScheme.surfaceContainerLow,
          border: Border.all(
            color: active
                ? colorScheme.onSurface
                : colorScheme.surfaceContainerHigh,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: active ? colorScheme.surface : colorScheme.onSurface,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ColumnSelector extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ColumnSelector({
    required this.current,
    required this.onSelect,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [1, 2].map((count) {
        final isActive = current == count;
        return GestureDetector(
          onTap: () => onSelect(count),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.onSurface
                  : colorScheme.surfaceContainerLow,
              border: Border.all(
                color: isActive
                    ? colorScheme.onSurface
                    : colorScheme.surfaceContainerHigh,
              ),
              borderRadius: isActive == (count == 1)
                  ? const BorderRadius.horizontal(left: Radius.circular(0))
                  : const BorderRadius.horizontal(right: Radius.circular(0)),
            ),
            child: Center(
              child: Text(
                '$count',
                style: textTheme.labelMedium?.copyWith(
                  color: isActive ? colorScheme.surface : colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
