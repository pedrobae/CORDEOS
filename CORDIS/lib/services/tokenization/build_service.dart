import 'dart:math';

import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:cordis/widgets/ciphers/editor/sections/chord_token.dart';
import 'package:flutter/material.dart';

class TokenizationBuilder {
  const TokenizationBuilder();

  /// Measures text dimensions.
  ///
  /// Cache key includes all relevant style properties (fontFamily, fontSize, fontWeight, letterSpacing)
  /// to avoid cache collisions between different text styles.
  ///
  /// Returns [Measurements] containing width, height, baseline, and size.
  Measurements measureText({
    required String text,
    required TextStyle style,
    Map<String, Measurements>? cache,
  }) {
    cache ??= {};
    final key =
        '$text|${style.fontFamily}|${style.fontSize}|'
        '${style.fontWeight?.index}|${style.letterSpacing}';
    return cache.putIfAbsent(key, () {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      final measurements = Measurements(
        width: textPainter.width,
        height: textPainter.height,
        baseline: textPainter.computeDistanceToActualBaseline(
          TextBaseline.alphabetic,
        ),
        size: style.fontSize ?? 14.0,
      );

      return measurements;
    });
  }

  /// Builds widgets for viewing mode, with their sizes pre-calculated.
  ///
  /// Creates read-only text widgets for chords and lyrics.
  /// Returns organized structure with lines -> words -> widgets.
  /// Widget sizes are measured and cached for efficient positioning.
  OrganizedWidgets buildViewWidgets({
    required OrganizedTokens organizedTokens,
    required List<ContentToken> tokens,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
  }) {
    final lines = <WidgetLine>[];

    final msrCache = <String, Measurements>{};

    for (var line in organizedTokens.lines) {
      final words = <WidgetWord>[];
      for (var word in line.words) {
        final wordWidgets = <MeasuredWidget>[];
        for (var token in word.tokens) {
          switch (token.type) {
            case TokenType.chord:
              final measurement = measureText(
                text: token.text,
                style: chordStyle,
                cache: msrCache,
              );
              wordWidgets.add(
                MeasuredWidget(
                  widget: Text(token.text, style: chordStyle),
                  measurements: measurement,
                  type: TokenType.chord,
                  token: token,
                ),
              );
              break;
            case TokenType.lyric:
              final measurement = measureText(
                text: token.text,
                style: lyricStyle,
                cache: msrCache,
              );

              wordWidgets.add(
                MeasuredWidget(
                  widget: Text(token.text, style: lyricStyle),
                  measurements: measurement,
                  type: TokenType.lyric,
                  token: token,
                ),
              );
              break;
            case TokenType.space:
              final measurement = measureText(
                text: ' ',
                style: lyricStyle,
                cache: msrCache,
              );

              wordWidgets.add(
                MeasuredWidget(
                  widget: Text(' ', style: lyricStyle),
                  measurements: measurement,
                  type: TokenType.space,
                  token: token,
                ),
              );
              break;
            case TokenType.newline:
              // NEW LINE TOKENS INDICATE LINE BREAKS
              wordWidgets.add(
                MeasuredWidget(
                  widget: SizedBox.shrink(),
                  measurements: Measurements(
                    width: 0,
                    height: 0,
                    baseline: 0,
                    size: 0,
                  ),
                  type: TokenType.newline,
                  token: token,
                ),
              );
              break;
            case TokenType.precedingChordTarget:
            case TokenType.underline:
              break;
          }
        }
        if (wordWidgets.isNotEmpty) {
          words.add(WidgetWord(wordWidgets));
        }
      }
      if (words.isNotEmpty) {
        lines.add(WidgetLine(words));
      }
    }

    return OrganizedWidgets(lines);
  }

  /// Builds widgets with drag-and-drop capabilities for editing mode.
  ///
  /// Creates interactive widgets:
  /// - Draggable chord widgets that can be moved
  /// - Drop target widgets for lyrics and spaces
  /// - Preceding chord targets for line-start positioning
  ///
  /// Returns organized structure with lines -> words -> widgets.
  OrganizedWidgets buildEditWidgets({
    required OrganizedTokens contentTokens,
    required List<ContentToken> tokens,
    required EditBuildContext ctx,
    required TokenPositionMap tokenPositions,
  }) {
    /// Build all token widgets, and calculate their sizes for positioning
    final lines = <WidgetLine>[];
    int position = 0;
    for (var line in contentTokens.lines) {
      final words = <WidgetWord>[];
      for (var word in line.words) {
        final wordWidgets = <MeasuredWidget>[];
        for (var token in word.tokens) {
          switch (token.type) {
            case TokenType.precedingChordTarget:
              wordWidgets.add(
                MeasuredWidget(
                  widget: _buildPrecedingChordDragTarget(
                    ctx: ctx,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    position: position,
                    tokenPositions: tokenPositions,
                  ),
                  measurements: Measurements(
                    width: TokenizationConstants.precedingTargetWidth,
                    height: 0,
                    baseline: 0,
                    size: 0,
                  ),
                  type: TokenType.precedingChordTarget,
                  token: token,
                ),
              );
              break;
            case TokenType.chord:
              final measurement = measureText(
                text: token.text,
                style: ctx.chordStyle,
                cache: ctx.cache,
              );

              measurement.width += TokenizationConstants.chordTokenWidthPadding;

              wordWidgets.add(
                MeasuredWidget(
                  widget: _buildDraggableChord(
                    ctx: ctx,
                    token: token,
                    position: position,
                  ),
                  measurements: measurement,
                  type: TokenType.chord,
                  token: token,
                ),
              );
              break;
            case TokenType.lyric:
              final measurement = measureText(
                text: token.text,
                style: ctx.lyricStyle,
                cache: ctx.cache,
              );

              wordWidgets.add(
                MeasuredWidget(
                  widget: _buildLyricDragTarget(
                    ctx: ctx,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    position: position,
                    tokenPositions: tokenPositions,
                  ),
                  measurements: measurement,
                  type: TokenType.lyric,
                  token: token,
                ),
              );
              break;

            case TokenType.space:
              final measurement = measureText(
                text: ' ',
                style: ctx.lyricStyle,
                cache: ctx.cache,
              );

              wordWidgets.add(
                MeasuredWidget(
                  widget: _buildSpaceDragTarget(
                    ctx: ctx,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    position: position,
                    spaceMeasurements: measurement,
                    tokenPositions: tokenPositions,
                  ),
                  measurements: measurement,
                  type: TokenType.space,
                  token: token,
                ),
              );
              break;

            case TokenType.newline:
              // Newline tokens dont have fixed width
              wordWidgets.add(
                MeasuredWidget(
                  widget: SizedBox.shrink(),
                  measurements: Measurements(
                    width: 0,
                    height: 0,
                    baseline: 0,
                    size: 0,
                  ),
                  type: TokenType.newline,
                  token: token,
                ),
              );
              break;
            case TokenType.underline:
              break;
          }
          position++;
        }
        if (wordWidgets.isNotEmpty) {
          words.add(WidgetWord(wordWidgets));
        }
      }
      if (words.isNotEmpty) {
        lines.add(WidgetLine(words));
      }
    }
    return OrganizedWidgets(lines);
  }

  /// Generic drag target builder to reduce code duplication.
  /// Wraps a child widget with DragTarget functionality if enabled.
  Widget _buildGenericDragTarget({
    required EditBuildContext ctx,
    required Widget child,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required int position,
    required int Function(int originalIndex, int position) indexAdjuster,
    required Function(
      List<ContentToken> tokens,
      ContentToken token,
      int position,
    )
    onAccept,
    required TokenPositionMap tokenPositions,
  }) {
    return ctx.isEnabled
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              onAccept(tokens, details.data, position);
              if (details.data.position != null) {
                final index = indexAdjuster(details.data.position!, position);
                ctx.onRemoveChord(tokens, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  ctx: ctx,
                  dragTargetChild: child,
                  draggedChord: candidateData.first!,
                  draggedToToken: token,
                  tokenLine: tokenLine,
                  tokenPositions: tokenPositions,
                );
              }
              return child;
            },
          )
        : child;
  }

  Widget _buildDraggableChord({
    required EditBuildContext ctx,
    required ContentToken token,
    required int position,
  }) {
    // Assign position to token for reference
    token.position = position;

    // ChordTokens
    final chordWidget = ChordToken(
      token: token,
      sectionColor: ctx.contentColor,
      textStyle: ctx.chordStyle,
    );

    final dimChordWidget = ChordToken(
      token: token,
      sectionColor: ctx.contentColor.withValues(alpha: .5),
      textStyle: ctx.chordStyle,
    );

    // GestureDetector to handle long press to drag transition
    return ctx.isEnabled
        ? LongPressDraggable<ContentToken>(
            data: token,
            onDragStarted: ctx.toggleDrag,
            onDragEnd: (details) => ctx.toggleDrag(),
            feedback: Material(
              color: Colors.transparent,
              child: dimChordWidget,
            ),
            childWhenDragging: SizedBox.shrink(),
            child: chordWidget,
          )
        : chordWidget;
  }

  Widget _buildPrecedingChordDragTarget({
    required EditBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required int position,
    required TokenPositionMap tokenPositions,
  }) {
    // Calculate lyric measurements for positioning baseline
    final lyricMsr = measureText(
      text: 'teste',
      style: ctx.lyricStyle,
      cache: ctx.cache,
    );

    final dragTargetChild = SizedBox(
      height: lyricMsr.size,
      width: TokenizationConstants.precedingTargetWidth,
      child: Stack(
        children: [
          Positioned(
            top: lyricMsr.baseline,
            child: Container(
              color: Colors.grey.shade400,
              height: 2,
              width: TokenizationConstants.precedingTargetWidth,
            ),
          ),
        ],
      ),
    );

    return _buildGenericDragTarget(
      ctx: ctx,
      child: dragTargetChild,
      tokenLine: tokenLine,
      tokens: tokens,
      token: token,
      position: position,
      onAccept: ctx.onAddPrecedingChord,
      indexAdjuster: (originalIndex, pos) {
        // Adjust for two insertions (Chord + Space)
        return originalIndex > pos ? originalIndex + 2 : originalIndex;
      },
      tokenPositions: tokenPositions,
    );
  }

  Widget _buildLyricDragTarget({
    required EditBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required int position,
    required TokenPositionMap tokenPositions,
  }) {
    final dragTargetChild = Text(token.text, style: ctx.lyricStyle);

    return _buildGenericDragTarget(
      ctx: ctx,
      child: dragTargetChild,
      tokenLine: tokenLine,
      tokens: tokens,
      token: token,
      position: position,
      indexAdjuster: (originalIndex, pos) {
        return originalIndex > pos ? originalIndex + 1 : originalIndex;
      },
      onAccept: ctx.onAddChord,
      tokenPositions: tokenPositions,
    );
  }

  Widget _buildSpaceDragTarget({
    required EditBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required int position,
    required Measurements spaceMeasurements,
    required TokenPositionMap tokenPositions,
  }) {
    final dragTargetChild = SizedBox(
      width: spaceMeasurements.width,
      height: spaceMeasurements.height,
    );

    return _buildGenericDragTarget(
      ctx: ctx,
      child: dragTargetChild,
      tokenLine: tokenLine,
      tokens: tokens,
      token: token,
      position: position,
      onAccept: ctx.onAddChord,
      indexAdjuster: (originalIndex, pos) {
        return originalIndex > pos ? originalIndex + 1 : originalIndex;
      },
      tokenPositions: tokenPositions,
    );
  }

  /// Builds the feedback widget shown when dragging a chord over a valid target,
  /// Showing the chord above the target, with the close by tokens,
  /// Similar to what is shown when selecting text in a text editor, to give better context of where the chord will be dropped.
  Widget _buildDragTargetFeedback({
    required EditBuildContext ctx,
    required Widget dragTargetChild,
    required ContentToken draggedChord,
    required ContentToken draggedToToken,
    required TokenPositionMap tokenPositions,
    required TokenLine tokenLine,
  }) {
    final chordMsr = measureText(
      text: 'test',
      style: ctx.chordStyle,
      cache: ctx.cache,
    );
    final lyricMsr = measureText(
      text: 'test',
      style: ctx.lyricStyle,
      cache: ctx.cache,
    );
    // ISOLATE LYRIC TOKENS FOR THE FEEDBACK
    // SAVE THE INDEX OF THE DRAGGED TO TOKEN
    final lyricTokens = <ContentToken>[];
    int draggedToIndex = 0;
    bool foundDraggedTo = false;
    for (var word in tokenLine.words) {
      for (var token in word.tokens) {
        if (token.type == TokenType.lyric || token.type == TokenType.space) {
          if (!foundDraggedTo) {
            draggedToIndex++;
          }
          if (token == draggedToToken) {
            foundDraggedTo = true;
          }
          lyricTokens.add(token);
        }
      }
    }

    // SELECT THE TOKENS CUTOUT TO SHOW IN THE FEEDBACK
    final int startIndex = max(
      0,
      draggedToIndex - TokenizationConstants.dragFeedbackTokensBefore,
    );
    final int endIndex = min(
      lyricTokens.length,
      draggedToIndex + TokenizationConstants.dragFeedbackTokensAfter,
    );
    final cutoutTokens = lyricTokens.sublist(startIndex, endIndex);

    // BUILD CUTOUT WIDGETS
    final cutoutWidgets = <Positioned>[];
    double xOffset = 0.0;

    for (var token in cutoutTokens) {
      if (token == draggedToToken) {
        // Show dragged to token with the dragged chord above it
        cutoutWidgets.add(
          Positioned(
            left: xOffset,
            top: TokenizationConstants.dragFeedbackCutoutPadding,
            child: ChordToken(
              token: draggedChord,
              sectionColor: ctx.contentColor,
              textStyle: ctx.chordStyle,
            ),
          ),
        );
      }
      cutoutWidgets.add(
        Positioned(
          left: xOffset,
          bottom:
              TokenizationConstants.dragFeedbackCutoutPadding -
              lyricMsr.bottomPadding,
          child: Text(token.text, style: ctx.lyricStyle),
        ),
      );
      xOffset +=
          measureText(
            text: token.text,
            style: ctx.lyricStyle,
            cache: ctx.cache,
          ).width +
          1;
    }

    final draggedToX = tokenPositions.getX(draggedToToken) ?? 0.0;

    double cutoutXOffset;
    if (draggedToX < TokenizationConstants.dragFeedbackCutoutWidth / 2) {
      // Too close to left edge - align cutout to left edge of content
      cutoutXOffset = -draggedToX;
    } else if (draggedToX >
        ctx.maxWidth - TokenizationConstants.dragFeedbackCutoutWidth / 2) {
      // Too close to right edge - align cutout to right edge of content
      cutoutXOffset =
          (ctx.maxWidth - draggedToX) -
          TokenizationConstants.dragFeedbackCutoutWidth;
    } else {
      // Enough space on both sides - center cutout on token
      cutoutXOffset = -TokenizationConstants.dragFeedbackCutoutWidth / 2;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        dragTargetChild,
        Positioned(
          bottom: lyricMsr.height,
          left: cutoutXOffset,
          child: Container(
            height:
                lyricMsr.size +
                chordMsr.height +
                TokenizationConstants.chordTokenHeightPadding +
                2 * TokenizationConstants.dragFeedbackCutoutPadding,
            width: TokenizationConstants.dragFeedbackCutoutWidth,
            padding: const EdgeInsets.symmetric(
              vertical: TokenizationConstants.dragFeedbackCutoutPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: ctx.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: ctx.onSurfaceColor,
                  blurRadius: 8,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Stack(children: cutoutWidgets),
          ),
        ),
      ],
    );
  }

  PositionedWithRef buildUnderlineWidget({
    required double width,
    required double leftOffset,
    required Measurements lyricMeasurements,
    required double topOffset,
    required Color color,
  }) {
    lyricMeasurements.width = width;

    final underLine = SizedBox(
      height: lyricMeasurements.size,
      width: width,
      child: Stack(
        children: [
          Positioned(
            top: lyricMeasurements.baseline,
            width: width,
            child: Container(width: width, height: 2, color: color),
          ),
        ],
      ),
    );

    return PositionedWithRef(
      positioned: Positioned(
        left: leftOffset,
        top: topOffset,
        width: width,
        child: underLine,
      ),
      ref: MeasuredWidget(
        widget: underLine,
        measurements: lyricMeasurements,
        type: TokenType.underline,
        token: ContentToken(text: '', type: TokenType.underline),
      ),
    );
  }
}
