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
class PagePreviewSnapshot {
  final Map<int, SectionPaintModel> sectionModels;
  final Map<int, TextPainter> sectionLabelPainters;
  final List<TextPaintInstruction> metadataInstructions;
  final double metadataBlockHeight;
  final double sectionLabelHeight;

  const PagePreviewSnapshot({
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
    required Map<int, SectionPrintCache> sections,
    required Map<String, Measurements> tokenMeasurements,
    required HeaderData header,
    required TokenizationBuilder builder,
    required PrintingContext ctx,
  }) {
    // Build per-section paint models
    final models = <int, SectionPaintModel>{};
    final sectionLabelPainters = <int, TextPainter>{};
    final seenTypes = <SectionType>{};
    for (final key in sections.keys) {
      final section = sections[key]!;

      if (section.type == SectionType.annotation && !ctx.showAnnotations) {
        continue;
      }
      if (seenTypes.contains(section.type) && !ctx.showRepeatSections) {
        continue;
      }
      seenTypes.add(section.type);

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

      final labelPainter = TextPainter(
        text: TextSpan(text: section.label, style: ctx.labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: ctx.maxWidth);
      sectionLabelPainters[key] = labelPainter;
    }

    // Build metadata header instructions
    final metaLines = _buildMetadataLines(ctx: ctx, header: header);
    final instructions = <TextPaintInstruction>[];
    double y = 0;
    for (final (text, style) in metaLines) {
      if (text.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: ctx.maxWidth);
      instructions.add(
        TextPaintInstruction(painter: painter, offset: Offset(0, y)),
      );
      y += painter.height;
    }

    return PagePreviewSnapshot(
      sectionModels: models,
      sectionLabelPainters: sectionLabelPainters,
      metadataInstructions: instructions,
      metadataBlockHeight: y,
      sectionLabelHeight: sectionLabelPainters.isEmpty
          ? 0
          : (sectionLabelPainters.values.first.height + 4),
    );
  }

  static List<(String, TextStyle)> _buildMetadataLines({
    required PrintingContext ctx,
    required HeaderData header,
  }) {
    final detailParts = <String>[header.author, header.musicKey];
    if (ctx.showBpm && (header.bpm ?? 0) > 0) {
      detailParts.add('${header.bpmLabel}: ${header.bpm}');
    }
    final formattedDuration = DateTimeUtils.formatDuration(header.duration);
    if (ctx.showDuration && formattedDuration.isNotEmpty) {
      detailParts.add('${header.durationLabel}: $formattedDuration');
    }

    return [
      (
        header.title,
        ctx.metadataStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: (ctx.metadataStyle.fontSize ?? 12) + 2,
        ),
      ),
      (detailParts.join('  •  '), ctx.metadataStyle),
      if (ctx.showSongMap)
        (
          '${header.songMapLabel}: ${header.codeSongMap.join('|')}',
          ctx.metadataStyle.copyWith(
            fontSize: (ctx.metadataStyle.fontSize ?? 11) - 1,
          ),
        ),
    ];
  }
}

class PageContext {
  final double pageWidth;
  final double pageHeight;
  final double horizontalMargin;
  final double verticalMargin;
  final double columnGap;
  final double sectionSpacing;
  final int columnCount;

  PageContext({
    required this.pageWidth,
    required this.pageHeight,
    required this.horizontalMargin,
    required this.verticalMargin,
    required this.columnGap,
    required this.sectionSpacing,
    required this.columnCount,
  });

  double get sectionWidth =>
      (pageWidth - horizontalMargin * 2 - columnGap * (columnCount - 1)) /
      columnCount;
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
  final List<SectionPlacement> placements;

  const PageLayout({required this.placements});
}

/// [CustomPainter] that renders a page preview using pre-computed
/// [PagePreviewSnapshot] data. Pixel-perfect scaling is handled by
/// the caller via [LayoutBuilder] — this painter works in logical page units.
class PagePreviewPainter extends CustomPainter {
  final PagePreviewSnapshot snapshot;
  final List<PageLayout> pages;
  final int pageIndex;

  final PageContext ctx;

  /// Background and rule colors.
  final Color pageColor;
  final Color shadowColor;

  const PagePreviewPainter({
    required this.snapshot,
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
    canvas.translate(ctx.horizontalMargin, ctx.verticalMargin);

    if (pageIndex == 0) _paintHeader(canvas, snapshot.metadataInstructions);

    for (final placement in pages[pageIndex].placements) {
      final model = snapshot.sectionModels[placement.sectionKey]!;
      _paintSectionSlice(canvas, model, placement);
    }

    canvas.restore();
  }

  void _paintHeader(
    Canvas canvas,
    List<TextPaintInstruction> metadataInstructions,
  ) {
    // Paint all metadata text instructions at their computed positions
    for (final instruction in metadataInstructions) {
      instruction.painter.paint(canvas, instruction.offset);
    }
  }

  void _paintSectionSlice(
    Canvas canvas,
    SectionPaintModel model,
    SectionPlacement placement,
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

    final painter = snapshot.sectionLabelPainters[placement.sectionKey];
    painter?.paint(canvas, Offset(placement.xOffset, placement.yOffset));

    for (final instruction in model.textInstructions) {
      instruction.painter.paint(
        canvas,
        Offset(
          placement.xOffset + instruction.offset.dx,
          placement.yOffset +
              instruction.offset.dy +
              snapshot.sectionLabelHeight,
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
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.pages != pages ||
        oldDelegate.pageIndex != pageIndex;
  }
}
