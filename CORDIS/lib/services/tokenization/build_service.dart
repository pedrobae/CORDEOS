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
    required Map<ContentToken, Measurements> tokenMeasurements,
    required List<ContentToken> tokens,
    required TokenBuildContext ctx,
    required TokenPositionMap tokenPositions,
  }) {
    final lines = <WidgetLine>[];

    for (var line in organizedTokens.lines) {
      final words = <WidgetWord>[];
      for (var word in line.words) {
        final wordWidgets = <TokenWidget>[];
        for (var token in word.tokens) {
          switch (token.type) {
            case TokenType.chord:
              wordWidgets.add(
                TokenWidget(
                  widget: Text(
                    ctx.transposeChord(token.text),
                    style: ctx.chordStyle,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.lyric:
              wordWidgets.add(
                TokenWidget(
                  widget: Text(token.text, style: ctx.lyricStyle),
                  token: token,
                ),
              );
              break;
            case TokenType.space:
              wordWidgets.add(
                TokenWidget(
                  widget: Text(' ', style: ctx.lyricStyle),
                  token: token,
                ),
              );
              break;
            case TokenType.newline:
              // NEW LINE TOKENS INDICATE LINE BREAKS
              wordWidgets.add(
                TokenWidget(widget: SizedBox.shrink(), token: token),
              );
              break;
            case TokenType.precedingChordTarget:
              // Preceding chord targets are only relevant in edit mode, so we skip them in view mode
              break;
            case TokenType.underline:
              wordWidgets.add(
                TokenWidget(
                  widget: buildUnderlineWidget(
                    msr: tokenMeasurements[token]!,
                    color: ctx.onSurfaceColor,
                  ),
                  token: token,
                ),
              );
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
    required Map<ContentToken, Measurements> tokenMeasurements,
    required List<ContentToken> tokens,
    required TokenBuildContext ctx,
    required TokenPositionMap tokenPositions,
  }) {
    /// Build all token widgets, and calculate their sizes for positioning
    final lines = <WidgetLine>[];
    for (var line in contentTokens.lines) {
      final words = <WidgetWord>[];
      for (var word in line.words) {
        final wordWidgets = <TokenWidget>[];
        for (var token in word.tokens) {
          switch (token.type) {
            case TokenType.precedingChordTarget:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildPrecedingChordDragTarget(
                    ctx: ctx,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.chord:
              wordWidgets.add(
                TokenWidget(
                  widget: buildDraggableChord(ctx: ctx, token: token),
                  token: token,
                ),
              );
              break;
            case TokenType.lyric:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildLyricDragTarget(
                    ctx: ctx,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                  ),
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
                TokenWidget(
                  widget: _buildSpaceDragTarget(
                    ctx: ctx,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    spaceMeasurements: measurement,
                    tokenPositions: tokenPositions,
                  ),
                  token: token,
                ),
              );
              break;

            case TokenType.newline:
              // Newline tokens dont have fixed width
              wordWidgets.add(
                TokenWidget(widget: SizedBox.shrink(), token: token),
              );
              break;
            case TokenType.underline:
              wordWidgets.add(
                TokenWidget(
                  widget: buildUnderlineWidget(
                    msr: tokenMeasurements[token]!,
                    color: ctx.onSurfaceColor,
                  ),
                  token: token,
                ),
              );
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

  Widget buildDraggableChord({
    required TokenBuildContext ctx,
    required ContentToken token,
  }) {
    // ChordTokens
    final chordWidget = ChordToken(
      token: token,
      sectionColor: ctx.contentColor,
      textStyle: ctx.lyricStyle,
    );

    final dimChordWidget = ChordToken(
      token: token,
      sectionColor: ctx.contentColor.withValues(alpha: .5),
      textStyle: ctx.lyricStyle,
    );

    // GestureDetector to handle long press to drag transition
    return ctx.isEnabled!
        ? LongPressDraggable<ContentToken>(
            data: token,
            onDragStarted: ctx.toggleDrag,
            onDragEnd: (details) => ctx.toggleDrag!(),
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
    required TokenBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
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
      tokenBuildCtx: ctx,
      child: dragTargetChild,
      token: token,
      onAccept: ctx.onAddPrecedingChord!,

      tokenLine: tokenLine,
      tokenPositions: tokenPositions,
    );
  }

  Widget _buildLyricDragTarget({
    required TokenBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required TokenPositionMap tokenPositions,
  }) {
    final dragTargetChild = Text(token.text, style: ctx.lyricStyle);

    return _buildGenericDragTarget(
      tokenBuildCtx: ctx,
      child: dragTargetChild,
      tokenLine: tokenLine,
      token: token,
      onAccept: ctx.onAddChord!,
      tokenPositions: tokenPositions,
    );
  }

  Widget _buildSpaceDragTarget({
    required TokenBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required Measurements spaceMeasurements,
    required TokenPositionMap tokenPositions,
  }) {
    final dragTargetChild = SizedBox(
      width: spaceMeasurements.width,
      height: spaceMeasurements.height,
    );

    return _buildGenericDragTarget(
      tokenBuildCtx: ctx,
      child: dragTargetChild,
      tokenLine: tokenLine,
      token: token,
      onAccept: ctx.onAddChord!,
      tokenPositions: tokenPositions,
    );
  }

  /// Generic drag target builder to reduce code duplication.
  /// Wraps a child widget with DragTarget functionality if enabled.
  Widget _buildGenericDragTarget({
    required TokenBuildContext tokenBuildCtx,
    required Widget child,
    required ContentToken token,
    required Function(ContentToken draggable, ContentToken target) onAccept,
    // Feedback
    required TokenLine tokenLine,
    required TokenPositionMap tokenPositions,
  }) {
    return tokenBuildCtx.isEnabled!
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              tokenBuildCtx.onRemoveChord!(details.data);
              onAccept(details.data, token);
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  ctx: tokenBuildCtx,
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

  /// Builds the feedback widget shown when dragging a chord over a valid target,
  /// Showing the chord above the target, with the close by tokens,
  /// Similar to what is shown when selecting text in a text editor, to give better context of where the chord will be dropped.
  Widget _buildDragTargetFeedback({
    required TokenBuildContext ctx,
    required Widget dragTargetChild,
    required ContentToken draggedChord,
    required ContentToken draggedToToken,
    required TokenPositionMap tokenPositions,
    required TokenLine tokenLine,
  }) {
    final chordMsr = measureText(
      text: draggedChord.text,
      style: ctx.chordStyle,
      cache: ctx.cache,
    );
    final lyricMsr = measureText(
      text: draggedToToken.text,
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
            bottom: lyricMsr.size + TokenizationConstants.dragFeedbackCutoutPadding,
            child: Text(
              ctx.transposeChord(draggedChord.text),
              style: ctx.lyricStyle.copyWith(color: ctx.onSurfaceColor),
              textHeightBehavior: TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
            ),
          ),
        );
      }
      cutoutWidgets.add(
        Positioned(
          left: xOffset,
          bottom: TokenizationConstants.dragFeedbackCutoutPadding,
          child: Text(
            token.text,
            style: ctx.lyricStyle,
            textHeightBehavior: TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
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
                chordMsr.size +
                2 * TokenizationConstants.dragFeedbackCutoutPadding,
            width: TokenizationConstants.dragFeedbackCutoutWidth,
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

  Widget buildUnderlineWidget({
    required Measurements msr,
    required Color color,
  }) {
    return SizedBox(
      height: msr.height,
      width: msr.width,
      child: Stack(
        children: [
          Positioned(
            top: msr.baseline,
            width: msr.width,
            child: Container(width: msr.width, height: 1, color: color),
          ),
        ],
      ),
    );
  }
}
