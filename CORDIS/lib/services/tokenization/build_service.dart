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
    bool isChordToken = false,
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
        width:
            textPainter.width +
            (isChordToken
                ? 2 * TokenizationConstants.chordTokenWidthPadding
                : 0.0), // Add horizontal padding for chord tokens to prevent overlap
        height:
            textPainter.height +
            (isChordToken
                ? 2 * TokenizationConstants.chordTokenHeightPadding
                : 0.0), // Add vertical padding for chord tokens to prevent overlap
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
            case TokenType.preSeparator:
            case TokenType.postSeparator:
            case TokenType.chordTarget:
              // Preceding chord targets and separators are only relevant in edit mode, so we skip
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
            case TokenType.preSeparator:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildChordTarget(
                    ctx: ctx,
                    tokenMeasurements: tokenMeasurements,

                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.chordTarget:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildChordTarget(
                    ctx: ctx,
                    tokenMeasurements: tokenMeasurements,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.postSeparator:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildChordTarget(
                    ctx: ctx,
                    tokenMeasurements: tokenMeasurements,
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
                    tokenMeasurements: tokenMeasurements,
                    tokenPositions: tokenPositions,
                  ),
                  token: token,
                ),
              );
              break;

            case TokenType.space:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildSpaceDragTarget(
                    ctx: ctx,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenMeasurements: tokenMeasurements,
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
      chordStyle: ctx.chordStyle,
    );

    final dimChordWidget = ChordToken(
      token: token,
      sectionColor: ctx.contentColor.withValues(alpha: .5),
      chordStyle: ctx.chordStyle,
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

  Widget _buildChordTarget({
    required TokenBuildContext ctx,
    required Map<ContentToken, Measurements> tokenMeasurements,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required TokenPositionMap tokenPositions,
  }) {
    final dragTargetChild = Container(
      decoration: BoxDecoration(
        color: ctx.chordTargetColor,
        borderRadius: BorderRadius.circular(20),
      ),
      width: tokenMeasurements[token]!.width,
      height: tokenMeasurements[token]!.height,
    );

    return _buildGenericDragTarget(
      buildCtx: ctx,
      tokenMeasurements: tokenMeasurements,
      child: dragTargetChild,
      token: token,
      tokenLine: tokenLine,
      tokenPositions: tokenPositions,
      isChordTarget: true,
    );
  }

  Widget _buildLyricDragTarget({
    required TokenBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required Map<ContentToken, Measurements> tokenMeasurements,
    required TokenPositionMap tokenPositions,
  }) {
    final dragTargetChild = Text(token.text, style: ctx.lyricStyle);

    return _buildGenericDragTarget(
      buildCtx: ctx,
      tokenMeasurements: tokenMeasurements,
      child: dragTargetChild,
      tokenLine: tokenLine,
      token: token,
      tokenPositions: tokenPositions,
    );
  }

  Widget _buildSpaceDragTarget({
    required TokenBuildContext ctx,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required Map<ContentToken, Measurements> tokenMeasurements,
    required TokenPositionMap tokenPositions,
  }) {
    final dragTargetChild = SizedBox(
      width: tokenMeasurements[token]!.width,
      height: tokenMeasurements[token]!.height,
    );

    return _buildGenericDragTarget(
      buildCtx: ctx,
      tokenMeasurements: tokenMeasurements,
      child: dragTargetChild,
      tokenLine: tokenLine,
      token: token,
      tokenPositions: tokenPositions,
    );
  }

  /// Generic drag target builder to reduce code duplication.
  /// Wraps a child widget with DragTarget functionality if enabled.
  Widget _buildGenericDragTarget({
    required TokenBuildContext buildCtx,
    required Map<ContentToken, Measurements> tokenMeasurements,
    required Widget child,
    required ContentToken token,
    required TokenLine tokenLine,
    required TokenPositionMap tokenPositions,
    bool isChordTarget = false,
  }) {
    return buildCtx.isEnabled!
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              buildCtx.onRemoveChord!(details.data);
              buildCtx.onAddChord!(details.data, token);
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  tokenMeasurements: tokenMeasurements,
                  ctx: buildCtx,
                  dragTargetChild: child,
                  draggedChord: candidateData.first!,
                  draggedToToken: token,
                  tokenLine: tokenLine,
                  tokenPositions: tokenPositions,
                  isChordTarget: isChordTarget,
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
    required Map<ContentToken, Measurements> tokenMeasurements,
    required ContentToken draggedChord,
    required ContentToken draggedToToken,
    required TokenPositionMap tokenPositions,
    required TokenLine tokenLine,
    required bool isChordTarget,
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
        if (token.type == TokenType.lyric ||
            token.type == TokenType.space ||
            token.type == TokenType.postSeparator ||
            token.type == TokenType.preSeparator) {
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

    // BUILD CUTOUT WIDGETS
    final cutoutWidgets = <Positioned>[];
    final midPoint =
        (TokenizationConstants.dragFeedbackCutoutWidth -
            measureText(
              text: ctx.transposeChord(draggedChord.text),
              style: ctx.lyricStyle,
              cache: ctx.cache,
            ).width) /
        2; // Start with dragged chord centered in cutout

    double xOffset = midPoint - 1;
    // build widgets before the dragged to token
    for (int i = draggedToIndex - 1; i >= 0; i--) {
      final token = lyricTokens[i];
      if (i != draggedToIndex - 1) {
        xOffset -=
            measureText(
              text: token.text,
              style: ctx.lyricStyle,
              cache: ctx.cache,
            ).width +
            1;
      }
      if (token.type != TokenType.preSeparator &&
          token.type != TokenType.postSeparator) {
        cutoutWidgets.add(
          Positioned(
            left: xOffset,
            bottom: TokenizationConstants.dragFeedbackCutoutPadding,
            child: Text(token.text, style: ctx.lyricStyle),
          ),
        );
      }
    }

    xOffset = midPoint;

    // build dragged chord widget
    cutoutWidgets.add(
      Positioned(
        left: xOffset,
        bottom: lyricMsr.size + TokenizationConstants.dragFeedbackCutoutPadding,
        child: Text(
          ctx.transposeChord(draggedChord.text),
          style: ctx.lyricStyle,
        ),
      ),
    );

    xOffset +=
        measureText(
          text: draggedToToken.text,
          style: ctx.lyricStyle,
          cache: ctx.cache,
        ).width +
        1;

    // build widgets after the dragged to token
    for (int i = draggedToIndex; i < lyricTokens.length; i++) {
      final token = lyricTokens[i];

      if (token.type != TokenType.preSeparator &&
          token.type != TokenType.postSeparator) {
        cutoutWidgets.add(
          Positioned(
            left: xOffset,
            bottom: TokenizationConstants.dragFeedbackCutoutPadding,
            child: Text(token.text, style: ctx.lyricStyle),
          ),
        );
      }

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
