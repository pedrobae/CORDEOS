import 'package:cordeos/models/dtos/song_pdf_dto.dart';
import 'package:cordeos/services/tokenization/build_service.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:flutter/material.dart';

/// Immutable snapshot of pre-computed instructions for painting a single page.
///
/// Constructing this object is the only place where TextPainters are built,
/// keeping [PagePreviewPainter.paint] allocation-free.
class PagePreviewSnapshot {
  final Map<int, SectionType> types;
  final Map<int, SectionPaintModel> sectionModels;
  final Map<int, TextPainter> sectionLabelPainters;
  final List<TextPaintInstruction> metadataInstructions;
  final double metadataBlockHeight;
  final double sectionLabelHeight;

  const PagePreviewSnapshot({
    required this.types,
    required this.sectionModels,
    required this.sectionLabelPainters,
    required this.metadataInstructions,
    required this.metadataBlockHeight,
    required this.sectionLabelHeight,
  });

  /// Builds the snapshot from a [SongPdfDto] and style overrides.
  /// Call this outside of [paint] — typically in [State.setState] or after
  /// [PrintingProvider.buildSongPdfDto] resolves.
  static PagePreviewSnapshot build({
    required SongPdfDto dto,
    required TokenizationBuilder builder,
    required SongPreviewDisplayOptions opt,
  }) {
    // Build per-section paint models
    final models = <int, SectionPaintModel>{};
    final sectionLabelPainters = <int, TextPainter>{};
    for (final key in dto.content.keys) {
      final localPositions = _toLocalPositionMap(
        dto.content[key]!,
        dto.sectionOffsets[key] ?? 0,
      );

      final lyricStyle = (dto.badgesData[key]!.type == SectionType.annotation)
          ? dto.lyricsStyle.copyWith(fontStyle: FontStyle.italic)
          : dto.lyricsStyle;

      models[key] = builder.buildPaintModel(
        measurements: dto.tokenMeasurements,
        positions: localPositions,
        chordStyle: dto.chordsStyle,
        lyricStyle: lyricStyle,
        chordColor: dto.chordsStyle.color!,
        lyricColor: lyricStyle.color!,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: opt.labelData[key]!.label,
          style: dto.sectionLabelStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: dto.layoutWidth);
      sectionLabelPainters[key] = labelPainter;
    }

    // Build metadata header instructions
    final metaLines = _buildMetadataLines(
      dto,
      showSongMap: opt.showSongMap,
      showBpm: opt.showBpm,
      showDuration: opt.showDuration,
      songMapLabel: opt.songMapLabel,
      bpmLabel: opt.bpmLabel,
      durationLabel: opt.durationLabel,
    );
    final instructions = <TextPaintInstruction>[];
    double y = 0;
    for (final (text, style) in metaLines) {
      if (text.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: dto.pageContentWidth);
      instructions.add(
        TextPaintInstruction(painter: painter, offset: Offset(0, y)),
      );
      y += painter.height + 2;
    }

    return PagePreviewSnapshot(
      types: dto.badgesData.map((key, value) => MapEntry(key, value.type)),
      sectionModels: models,
      sectionLabelPainters: sectionLabelPainters,
      metadataInstructions: instructions,
      metadataBlockHeight: y,
      sectionLabelHeight: sectionLabelPainters.isEmpty
          ? 0
          : (sectionLabelPainters.values.first.height + 4),
    );
  }

  static TokenPositionMap _toLocalPositionMap(
    TokenPositionMap global,
    double yOffset,
  ) {
    final local = TokenPositionMap(
      lineHeight: global.lineHeight,
      contentWidth: global.contentWidth,
    );
    local.contentHeight = global.contentHeight;
    for (final entry in global.tokens.entries) {
      local.setPosition(entry.key, entry.value.dx, entry.value.dy - yOffset);
    }
    return local;
  }

  static List<(String, TextStyle)> _buildMetadataLines(
    SongPdfDto dto, {
    required bool showSongMap,
    required bool showBpm,
    required bool showDuration,
    required String songMapLabel,
    required String bpmLabel,
    required String durationLabel,
  }) {
    final detailParts = <String>[dto.author, dto.musicKey];
    if (showBpm && dto.bpm > 0) {
      detailParts.add('$bpmLabel: ${dto.bpm}');
    }
    final formattedDuration = DateTimeUtils.formatDuration(dto.duration);
    if (showDuration && formattedDuration.isNotEmpty) {
      detailParts.add('$durationLabel: $formattedDuration');
    }

    return [
      (
        dto.title,
        dto.metadataStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: (dto.metadataStyle.fontSize ?? 12) + 2,
        ),
      ),
      (detailParts.join('  •  '), dto.metadataStyle),
      if (showSongMap)
        (
          '$songMapLabel: ${dto.songStructure.join(' • ')}',
          dto.metadataStyle.copyWith(
            fontSize: (dto.metadataStyle.fontSize ?? 11) - 1,
          ),
        ),
    ];
  }
}

class PageSlicePlacement {
  final int key;
  final int pageIndex;
  final int columnIndex;
  final double x;
  final double y;
  final bool showLabel;
  final double labelHeight;
  final double localTop;
  final double localBottom;

  const PageSlicePlacement({
    required this.key,
    required this.pageIndex,
    required this.columnIndex,
    required this.x,
    required this.y,
    required this.showLabel,
    required this.labelHeight,
    required this.localTop,
    required this.localBottom,
  });

  double get height => localBottom - localTop;
}

class PagePreviewLayout {
  final List<PageSlicePlacement> placements;
  final int pageCount;

  const PagePreviewLayout({required this.placements, required this.pageCount});

  List<PageSlicePlacement> placementsForPage(int pageIndex) => placements
      .where((placement) => placement.pageIndex == pageIndex)
      .toList();

  static PagePreviewLayout build({
    required SongPdfDto dto,
    required PagePreviewSnapshot snapshot,
    required bool showMetadata,
    required bool showRepeatSections,
    required bool showAnnotations,
    required bool showSectionLabels,
    required int columnCount,
    required double pageHeight,
    required double topMargin,
    required double columnGap,
    required double sectionSpacing,
    required double metadataGap,
  }) {
    final placements = <PageSlicePlacement>[];
    final visibleKeys = <int>[];
    final rendered = <int>{};

    for (final key in dto.songStructure) {
      final isRepeat = rendered.contains(key);
      final type = snapshot.types[key];
      if (isRepeat && !showRepeatSections) {
        continue;
      }
      if (type == SectionType.annotation && !showAnnotations) {
        continue;
      }
      rendered.add(key);
      visibleKeys.add(key);
    }

    if (visibleKeys.isEmpty) {
      return const PagePreviewLayout(placements: [], pageCount: 1);
    }

    final defaultColumnHeight = pageHeight - 2 * topMargin;
    final firstPageColumnHeight =
        defaultColumnHeight -
        (showMetadata ? snapshot.metadataBlockHeight + metadataGap : 0);
    final columnWidth = dto.layoutWidth;

    int pageIndex = 0;
    int columnIndex = 0;
    double cursorY = 0;

    double currentColumnHeight() =>
        pageIndex == 0 ? firstPageColumnHeight : defaultColumnHeight;

    void advanceSlot() {
      if (columnIndex < columnCount - 1) {
        columnIndex += 1;
      } else {
        pageIndex += 1;
        columnIndex = 0;
      }
      cursorY = 0;
    }

    for (final key in visibleKeys) {
      final model = snapshot.sectionModels[key];
      if (model == null) {
        continue;
      }

      final labelHeight = showSectionLabels ? snapshot.sectionLabelHeight : 0.0;
      double consumedHeight = 0;
      final modelHeight = model.size.height;
      final totalSectionHeight = modelHeight + labelHeight;

      // Keep sections intact when they can fit in a fresh column/page.
      // Only sections taller than a full non-metadata column are allowed to split.
      final canFitWithoutSplitting = totalSectionHeight <= defaultColumnHeight;
      if (canFitWithoutSplitting) {
        while (totalSectionHeight > (currentColumnHeight() - cursorY)) {
          advanceSlot();
        }
      }

      var isFirstSlice = true;

      while (consumedHeight < modelHeight) {
        var availableHeight = currentColumnHeight() - cursorY;
        if (availableHeight <= 0) {
          advanceSlot();
          availableHeight = currentColumnHeight() - cursorY;
        }

        final currentLabelHeight = isFirstSlice ? labelHeight : 0.0;
        final availableContentHeight = availableHeight - currentLabelHeight;
        if (availableContentHeight <= 0) {
          advanceSlot();
          continue;
        }

        final remainingHeight = modelHeight - consumedHeight;
        final sliceHeight = remainingHeight < availableContentHeight
            ? remainingHeight
            : availableContentHeight;

        placements.add(
          PageSlicePlacement(
            key: key,
            pageIndex: pageIndex,
            columnIndex: columnIndex,
            x: columnIndex * (columnWidth + columnGap),
            y: cursorY,
            showLabel: isFirstSlice && labelHeight > 0,
            labelHeight: currentLabelHeight,
            localTop: consumedHeight,
            localBottom: consumedHeight + sliceHeight,
          ),
        );

        consumedHeight += sliceHeight;
        cursorY += sliceHeight + currentLabelHeight;
        isFirstSlice = false;

        final finishedSection = (modelHeight - consumedHeight).abs() < 0.001;
        if (finishedSection) {
          cursorY += sectionSpacing;
        }
      }
    }

    return PagePreviewLayout(placements: placements, pageCount: pageIndex + 1);
  }
}

/// [CustomPainter] that renders a page preview using pre-computed
/// [PagePreviewSnapshot] data. Pixel-perfect scaling is handled by
/// the caller via [LayoutBuilder] — this painter works in logical page units.
class PagePreviewPainter extends CustomPainter {
  final PagePreviewSnapshot snapshot;
  final SongPdfDto dto;
  final PagePreviewLayout layout;
  final int pageIndex;

  /// Visual filters — do not require rebuilding the DTO or snapshot.
  final bool showMetadata;
  final bool showRepeatSections;
  final bool showAnnotations;

  /// Physical page dimensions in logical pixels (matching the coordinate
  /// space used when the DTO was built).
  final double pageWidth;
  final double pageHeight;
  final double horizontalMargin;
  final double topMargin;
  final double columnGap;
  final double sectionSpacing;

  /// Gap between the metadata block and the first section.
  final double metadataGap;

  /// Background and rule colors.
  final Color pageColor;
  final Color shadowColor;

  const PagePreviewPainter({
    required this.snapshot,
    required this.dto,
    required this.layout,
    required this.pageIndex,
    required this.showMetadata,
    required this.showRepeatSections,
    required this.showAnnotations,
    required this.pageWidth,
    required this.pageHeight,
    required this.horizontalMargin,
    required this.topMargin,
    required this.columnGap,
    required this.sectionSpacing,
    this.metadataGap = 12,
    this.pageColor = Colors.white,
    this.shadowColor = const Color(0x33000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // [size] is the widget's pixel size on screen. The parent [LayoutBuilder]
    // already scaled us so that `size.width == pageWidth`. We still scale
    // explicitly to keep the painter self-contained.
    final scale = size.width / pageWidth;
    canvas.scale(scale);

    // Page shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(Rect.fromLTWH(2, 2, pageWidth, pageHeight), shadowPaint);

    // Page background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, pageWidth, pageHeight),
      Paint()..color = pageColor,
    );

    // Clip to page bounds
    canvas.clipRect(Rect.fromLTWH(0, 0, pageWidth, pageHeight));

    // Translate to content area origin
    canvas.save();
    canvas.translate(horizontalMargin, topMargin);

    double contentY = 0;

    // Metadata header
    if (showMetadata && pageIndex == 0) {
      for (final instruction in snapshot.metadataInstructions) {
        instruction.painter.paint(
          canvas,
          Offset(instruction.offset.dx, instruction.offset.dy),
        );
      }
      contentY += snapshot.metadataBlockHeight + metadataGap;

      // Divider line below metadata
      canvas.drawLine(
        Offset(0, contentY - metadataGap / 2),
        Offset(dto.pageContentWidth, contentY - metadataGap / 2),
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 0.5,
      );
    }

    canvas.translate(0, contentY);

    for (final placement in layout.placementsForPage(pageIndex)) {
      final model = snapshot.sectionModels[placement.key];
      if (model == null) {
        continue;
      }

      _paintSectionSlice(canvas, model, placement);
    }

    canvas.restore();
  }

  void _paintSectionSlice(
    Canvas canvas,
    SectionPaintModel model,
    PageSlicePlacement placement,
  ) {
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        placement.x,
        placement.y,
        dto.layoutWidth,
        placement.height + placement.labelHeight,
      ),
    );

    if (placement.showLabel) {
      final painter = snapshot.sectionLabelPainters[placement.key];
      painter?.paint(canvas, Offset(placement.x, placement.y));
    }

    for (final instruction in model.textInstructions) {
      instruction.painter.paint(
        canvas,
        Offset(
          placement.x + instruction.offset.dx,
          placement.y +
              placement.labelHeight +
              instruction.offset.dy -
              placement.localTop,
        ),
      );
    }
    for (final underline in model.underlines) {
      canvas.drawLine(
        Offset(
          placement.x + underline.offset.dx,
          placement.y +
              placement.labelHeight +
              underline.offset.dy -
              placement.localTop,
        ),
        Offset(
          placement.x + underline.offset.dx + underline.width,
          placement.y +
              placement.labelHeight +
              underline.offset.dy -
              placement.localTop,
        ),
        Paint()
          ..color = model.underlineColor
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PagePreviewPainter oldDelegate) {
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.layout != layout ||
        oldDelegate.pageIndex != pageIndex ||
        oldDelegate.showMetadata != showMetadata ||
        oldDelegate.showRepeatSections != showRepeatSections ||
        oldDelegate.showAnnotations != showAnnotations;
  }
}
