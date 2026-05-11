import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/dtos/song_pdf_dto.dart';
import 'package:cordeos/providers/printing_provider.dart';
import 'package:cordeos/services/tokenization/build_service.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:flutter/material.dart';

/// Immutable snapshot of pre-computed instructions for painting a single page.
///
/// Constructing this object is the only place where TextPainters are built,
/// keeping [PagePreviewPainter.paint] allocation-free.
class PrintPreviewSnapshot {
  final PlaylistItemType type;
  final SongPPS? songSnapshot;
  final FlowPPS? flowSnapshot;

  const PrintPreviewSnapshot({
    required this.type,
    this.flowSnapshot,
    this.songSnapshot,
  });
}

class SongPPS {
  final List<int> songMap;
  final List<TextPaintInstruction> headerInstructions;
  final double headerBlockHeight;
  final Map<int, LabelPaintModel> sectionLabelPainters;
  final Map<int, BadgePaintModel> badgeModels;
  final Map<int, SectionPaintModel> sectionModels;
  final double sectionLabelHeight;

  const SongPPS({
    required this.songMap,
    required this.headerInstructions,
    required this.headerBlockHeight,
    required this.sectionLabelPainters,
    required this.badgeModels,
    required this.sectionModels,
    required this.sectionLabelHeight,
  });

  /// Builds the snapshot from a [SongPdfDto] and style overrides.
  /// Call this outside of [paint] — typically in [State.setState] or after
  /// [PrintingProvider.buildSongPdfDto] resolves.
  static SongPPS build({
    required List<int> songMap,
    required Map<int, SectionPrintCache> sections,
    required Map<String, Measurements> tokenMeasurements,
    required HeaderData headerData,
    required TokenizationBuilder builder,
    required PrintingContext ctx,
  }) {
    // Build per-section paint models
    final models = <int, SectionPaintModel>{};
    final labelPainters = <int, LabelPaintModel>{};
    final badgePainters = <int, BadgePaintModel>{};
    for (final key in sections.keys) {
      final section = sections[key]!;

      if (section.type == SectionType.annotation && !ctx.showAnnotations) {
        continue;
      }

      final lyricStyle = (section.type == SectionType.annotation)
          ? ctx.lyricStyle.copyWith(fontStyle: FontStyle.italic)
          : ctx.lyricStyle;

      models[key] = builder.buildPaintModel(
        sectionKey: key,
        measurements: tokenMeasurements,
        positions: section.positions!,
        chordStyle: ctx.chordStyle,
        lyricStyle: lyricStyle,
      );

      if (ctx.showSectionLabels) {
        final labelPainter = TextPainter(
          text: TextSpan(text: section.label, style: ctx.labelStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: ctx.contentWidth);

        labelPainters[key] = LabelPaintModel(
          key: key,
          style: ctx.labelStyle,
          textPainter: labelPainter,
        );

        final badgePainter = TextPainter(
          text: TextSpan(
            text: section.code,
            style: ctx.labelStyle.copyWith(
              fontStyle: FontStyle.normal,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: ctx.contentWidth);

        badgePainters[key] = BadgePaintModel(
          color: section.color,
          style: ctx.labelStyle.copyWith(
            fontStyle: FontStyle.normal,
            color: Colors.white,
          ),
          key: key,
          textPainter: badgePainter,
        );
      }
    }

    // Build header instructions
    final metaLines = ctx.showHeader
        ? _buildHeaderLines(ctx: ctx, headerData: headerData)
        : [];
    final instructions = <TextPaintInstruction>[];
    double y = 0;
    for (final (text, style) in metaLines) {
      if (text.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: (ctx.contentWidth));
      instructions.add(
        TextPaintInstruction(
          painter: painter,
          offset: Offset(0, y),
          style: style,
        ),
      );
      y += painter.height;
    }

    return SongPPS(
      badgeModels: badgePainters,
      songMap: songMap,
      sectionModels: models,
      sectionLabelPainters: labelPainters,
      headerInstructions: instructions,
      headerBlockHeight: y,
      sectionLabelHeight: labelPainters.isEmpty
          ? 0
          : (labelPainters.values.first.textPainter.height + 4),
    );
  }

  static List<(String, TextStyle)> _buildHeaderLines({
    required PrintingContext ctx,
    required HeaderData headerData,
  }) {
    final detailParts = <String>[headerData.author, headerData.musicKey];
    if (ctx.showBpm && (headerData.bpm ?? 0) > 0) {
      detailParts.add('${headerData.bpmLabel}: ${headerData.bpm}');
    }
    final formattedDuration = DateTimeUtils.formatDuration(headerData.duration);
    if (ctx.showDuration && formattedDuration.isNotEmpty) {
      detailParts.add('${headerData.durationLabel}: $formattedDuration');
    }

    return [
      (
        headerData.title,
        ctx.headerStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: (ctx.headerStyle.fontSize ?? 12) + 2,
        ),
      ),
      (detailParts.join('  •  '), ctx.headerStyle),
      if (ctx.showSongMap)
        (
          '${headerData.songMapLabel}: ${headerData.codeSongMap.join(' | ')}',
          ctx.headerStyle.copyWith(
            fontSize: (ctx.headerStyle.fontSize ?? 11) - 1,
          ),
        ),
    ];
  }
}

class FlowPPS {
  final TextPainter headerPainter;
  final TextStyle headerStyle;
  final double headerBlockHeight;

  final TextPainter contentPainter;
  final TextStyle contentStyle;
  final double contentHeight;

  const FlowPPS({
    required this.headerPainter,
    required this.headerStyle,
    required this.headerBlockHeight,
    required this.contentPainter,
    required this.contentStyle,
    required this.contentHeight,
  });

  static FlowPPS build({required FlowItem flow, required PrintingContext ctx}) {
    final headerPainter = TextPainter(
      text: TextSpan(
        text: flow.title,
        style: ctx.headerStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: (ctx.headerStyle.fontSize ?? 12) * 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: (ctx.maxWidth));

    final contentPainter = TextPainter(
      text: TextSpan(text: flow.contentText, style: ctx.lyricStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: ctx.maxWidth);

    return FlowPPS(
      headerPainter: headerPainter,
      headerBlockHeight: headerPainter.height,
      contentPainter: contentPainter,
      headerStyle: ctx.headerStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: (ctx.headerStyle.fontSize ?? 12) * 1.4,
      ),
      contentStyle: ctx.lyricStyle,
      contentHeight: contentPainter.height,
    );
  }
}

class PageContext {
  final double pageWidth;
  final double pageHeight;
  final double margin;
  final double columnGap;
  final double headerGap;
  final double sectionSpacing;
  final int columnCount;

  PageContext({
    required this.pageWidth,
    required this.pageHeight,
    required this.margin,
    required this.columnGap,
    required this.headerGap,
    required this.sectionSpacing,
    required this.columnCount,
  });

  double get sectionWidth =>
      (pageWidth - margin * 2 - columnGap * (columnCount - 1)) / columnCount;
}

class SectionPlacement {
  final int sectionKey;
  final int pageIndex;
  final int columnIndex;
  final double xOffset;
  final double yOffset;

  const SectionPlacement({
    required this.sectionKey,
    required this.pageIndex,
    required this.columnIndex,
    required this.xOffset,
    required this.yOffset,
  });
}

class PageLayout {
  final bool isFlow;
  final int snapshotIndex;
  final SongPageLayout? songPageLayout;

  const PageLayout({
    required this.isFlow,
    required this.snapshotIndex,
    required this.songPageLayout,
  });
}

class SongPageLayout {
  final List<SectionPlacement> placements;
  final bool showHeader;

  const SongPageLayout({required this.placements, this.showHeader = false});
}

/// [CustomPainter] that renders a page preview using pre-computed
/// [PagePreviewSnapshot] data. Pixel-perfect scaling is handled by
/// the caller via [LayoutBuilder] — this painter works in logical page units.
class PagePreviewPainter extends CustomPainter {
  final List<PrintPreviewSnapshot> snapshots;
  final List<PageLayout> pages;
  final int pageIndex;

  final PageContext ctx;

  /// Background and rule colors.
  final Color pageColor;
  final Color shadowColor;

  const PagePreviewPainter({
    required this.snapshots,
    required this.pages,
    required this.pageIndex,
    required this.ctx,
    this.pageColor = Colors.white,
    this.shadowColor = const Color(0x33000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // [size] is the widget's pixel size on screen. The parent [LayoutBuilder]
    // already scaled us so that `size.width == pageWidth`. We still scale
    // explicitly to keep the painter self-contained.
    final scale = size.width / ctx.pageWidth;
    canvas.scale(scale);

    // Page shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(
      Rect.fromLTWH(2, 2, ctx.pageWidth, ctx.pageHeight),
      shadowPaint,
    );

    // Page background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ctx.pageWidth, ctx.pageHeight),
      Paint()..color = pageColor,
    );

    // Clip to page bounds
    canvas.clipRect(Rect.fromLTWH(0, 0, ctx.pageWidth, ctx.pageHeight));

    // Translate to content area origin
    canvas.save();
    canvas.translate(ctx.margin, ctx.margin);

    final layout = pages[pageIndex];
    final snapshot = snapshots[layout.snapshotIndex];
    switch (snapshot.type) {
      case PlaylistItemType.version:
        final songLayout = layout.songPageLayout!;
        final songSnap = snapshot.songSnapshot!;
        if (songLayout.showHeader)
          _paintHeader(canvas, songSnap.headerInstructions);

        for (final placement in songLayout.placements) {
          final model = songSnap.sectionModels[placement.sectionKey]!;
          _paintSectionSlice(canvas, model, placement, songSnap);
        }
        break;
      case PlaylistItemType.flowItem:
        final flowSnap = snapshot.flowSnapshot!;

        flowSnap.headerPainter.paint(canvas, Offset.zero);
        flowSnap.contentPainter.paint(
          canvas,
          Offset(0, flowSnap.headerBlockHeight + ctx.headerGap),
        );
    }

    canvas.restore();
  }

  void _paintHeader(
    Canvas canvas,
    List<TextPaintInstruction> headerInstructions,
  ) {
    // Paint all header instructions at their computed positions
    for (final instruction in headerInstructions) {
      instruction.painter.paint(canvas, instruction.offset);
    }
  }

  void _paintSectionSlice(
    Canvas canvas,
    SectionPaintModel model,
    SectionPlacement placement,
    SongPPS snapshot,
  ) {
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        placement.xOffset,
        placement.yOffset,
        ctx.sectionWidth,
        model.size.height + snapshot.sectionLabelHeight + ctx.sectionSpacing,
      ),
    );

    final label = snapshot.sectionLabelPainters[placement.sectionKey];
    final badge = snapshot.badgeModels[placement.sectionKey];
    if ((snapshot.sectionLabelHeight > 0) && badge != null && label != null) {
      canvas.drawRRect(
        badge.rRect.shift(Offset(placement.xOffset, placement.yOffset)),
        Paint()..color = badge.color,
      );
      badge.textPainter.paint(
        canvas,
        Offset(placement.xOffset + 4, placement.yOffset + 2),
      );
      label.textPainter.paint(
        canvas,
        Offset(
          placement.xOffset + badge.textPainter.width + 12,
          placement.yOffset + 2,
        ),
      );
    }

    for (final instruction in model.textInstructions) {
      instruction.painter.paint(
        canvas,
        Offset(
          placement.xOffset + instruction.offset.dx,
          placement.yOffset +
              instruction.offset.dy +
              snapshot.sectionLabelHeight +
              4,
        ),
      );
    }
    for (final underline in model.underlines) {
      canvas.drawLine(
        Offset(
          placement.xOffset + underline.offset.dx,
          placement.yOffset + underline.offset.dy + snapshot.sectionLabelHeight,
        ),
        Offset(
          placement.xOffset + underline.offset.dx + underline.width,
          placement.yOffset + underline.offset.dy + snapshot.sectionLabelHeight,
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
    return true;
  }
}
