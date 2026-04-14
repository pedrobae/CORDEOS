import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/chord_token.dart';
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
    bool isChordToken = false,
  }) {
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
  }

  SectionPaintModel buildPaintModel({
    required Map<String, Measurements> measurements,
    required TokenPositionMap positions,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required Color lyricColor,
    required Color chordColor,
  }) {
    final texts = <TextPaintInstruction>[];
    final underlines = <UnderLinePaintInstruction>[];
    for (var entry in positions.tokens.entries) {
      final token = entry.key;
      final offset = entry.value;

      switch (token.type) {
        case TokenType.chord:
          final painter = TextPainter(
            text: TextSpan(
              text: token.text,
              style: chordStyle.copyWith(color: chordColor),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();

          texts.add(
            TextPaintInstruction(
              painter: painter,
              offset: Offset(offset.dx, offset.dy),
            ),
          );
          break;

        case TokenType.lyric:
          final painter = TextPainter(
            text: TextSpan(
              text: token.text,
              style: lyricStyle.copyWith(color: lyricColor),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();

          final msr = measurements[measurementKey(token.text, lyricStyle)]!;

          texts.add(
            TextPaintInstruction(
              painter: painter,
              offset: Offset(
                offset.dx,
                offset.dy + positions.lineHeight - msr.height,
              ),
            ),
          );
          break;

        case TokenType.underline:
          underlines.add(
            UnderLinePaintInstruction(
              offset: Offset(
                offset.dx,
                offset.dy + positions.lineHeight,
              ),
              width: measurements[token.toKey()]!.width,
            ),
          );
          break;

        case TokenType.space:
        case TokenType.newline:
        case TokenType.preSeparator:
        case TokenType.postSeparator:
        case TokenType.chordTarget:
          break;
      }
    }

    return SectionPaintModel(
      textInstructions: texts,
      underlines: underlines,
      size: Size(positions.contentWidth, positions.contentHeight!),
      underlineColor: lyricColor,
    );
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
    required List<ContentToken> tokens,
    required OrganizedTokens organizedTokens,
    required Map<String, Measurements> measurements,
    required TokenPositionMap tokenPositions,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double maxWidth,
    required double lineHeight,
    required double chordHeight,
    required Color chordTargetColor,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required Color contentColor,
    required Color onContentColor,
    required bool isEnabled,
    required Function(ContentToken, ContentToken) onAddChord,
    required Function(ContentToken) onRemoveChord,
    required Function() toggleDrag,
  }) {
    /// Build all token widgets
    final lines = <WidgetLine>[];
    for (var line in organizedTokens.lines) {
      final words = <WidgetWord>[];
      for (var word in line.words) {
        final wordWidgets = <TokenWidget>[];
        for (var token in word.tokens) {
          switch (token.type) {
            case TokenType.preSeparator:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildChordTarget(
                    tokenMeasurements: measurements,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                    chordTargetColor: chordTargetColor,
                    chordStyle: chordStyle,
                    lyricStyle: lyricStyle,
                    maxWidth: maxWidth,
                    lineHeight: lineHeight,
                    surfaceColor: surfaceColor,
                    onSurfaceColor: onSurfaceColor,
                    isEnabled: isEnabled,
                    onAddChord: onAddChord,
                    onRemoveChord: onRemoveChord,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.chordTarget:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildChordTarget(
                    tokenMeasurements: measurements,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                    lineHeight: lineHeight,
                    chordTargetColor: chordTargetColor,
                    chordStyle: chordStyle,
                    lyricStyle: lyricStyle,
                    maxWidth: maxWidth,
                    surfaceColor: surfaceColor,
                    onSurfaceColor: onSurfaceColor,
                    isEnabled: isEnabled,
                    onAddChord: onAddChord,
                    onRemoveChord: onRemoveChord,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.postSeparator:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildChordTarget(
                    tokenMeasurements: measurements,
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                    chordTargetColor: chordTargetColor,
                    chordStyle: chordStyle,
                    lyricStyle: lyricStyle,
                    maxWidth: maxWidth,
                    lineHeight: lineHeight,
                    surfaceColor: surfaceColor,
                    onSurfaceColor: onSurfaceColor,
                    isEnabled: isEnabled,
                    onAddChord: onAddChord,
                    onRemoveChord: onRemoveChord,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.chord:
              wordWidgets.add(
                TokenWidget(
                  widget: buildDraggableChord(
                    token: token,
                    contentColor: contentColor,
                    onContentColor: onContentColor,
                    chordStyle: chordStyle,
                    isEnabled: isEnabled,
                    toggleDrag: toggleDrag,
                  ),
                  token: token,
                ),
              );
              break;
            case TokenType.lyric:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildLyricDragTarget(
                    tokenLine: line,
                    tokens: tokens,
                    token: token,
                    tokenPositions: tokenPositions,
                    chordStyle: chordStyle,
                    lyricStyle: lyricStyle,
                    maxWidth: maxWidth,
                    surfaceColor: surfaceColor,
                    onSurfaceColor: onSurfaceColor,
                    isEnabled: isEnabled,
                    onAddChord: onAddChord,
                    onRemoveChord: onRemoveChord,
                    lineHeight: lineHeight,
                  ),
                  token: token,
                ),
              );
              break;

            case TokenType.space:
              wordWidgets.add(
                TokenWidget(
                  widget: _buildSpaceDragTarget(
                    tokenLine: line,
                    token: token,
                    tokenPositions: tokenPositions,
                    measurements: measurements,
                    chordStyle: chordStyle,
                    lyricStyle: lyricStyle,
                    maxWidth: maxWidth,
                    lineHeight: lineHeight,
                    surfaceColor: surfaceColor,
                    onSurfaceColor: onSurfaceColor,
                    isEnabled: isEnabled,
                    onAddChord: onAddChord,
                    onRemoveChord: onRemoveChord,
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
                  widget: IgnorePointer(
                    child: Container(
                      height: lineHeight,
                      width: measurements[token.toKey()]!.width,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: onSurfaceColor, width: 1),
                        ),
                      ),
                    ),
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
    required ContentToken token,
    required Color contentColor,
    required Color onContentColor,
    required TextStyle chordStyle,
    required bool isEnabled,
    required Function() toggleDrag,
  }) {
    // ChordTokens
    final chordWidget = ChordToken(
      token: token,
      sectionColor: contentColor,
      textColor: onContentColor,
      chordStyle: chordStyle,
    );

    final dimChordWidget = ChordToken(
      token: token,
      sectionColor: contentColor.withValues(alpha: .5),
      chordStyle: chordStyle,
      textColor: onContentColor,
    );

    // GestureDetector to handle long press to drag transition
    return isEnabled
        ? LongPressDraggable<ContentToken>(
            data: token,
            onDragStarted: toggleDrag,
            onDragEnd: (details) => toggleDrag(),
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
    required Map<String, Measurements> tokenMeasurements,
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required TokenPositionMap tokenPositions,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double maxWidth,
    required double lineHeight,
    required Color chordTargetColor,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required bool isEnabled,
    required Function(ContentToken, ContentToken) onAddChord,
    required Function(ContentToken) onRemoveChord,
  }) {
    final msr = token.type == TokenType.chordTarget
        ? tokenMeasurements[chordTargetKey(token.text, chordStyle, lyricStyle)]!
        : tokenMeasurements[separatorKey(chordStyle, lyricStyle)]!;

    final dragTargetChild = SizedBox(
      height: lineHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: surfaceColor, width: 0),
            color: chordTargetColor,
            borderRadius: BorderRadius.circular(20),
          ),
          width: msr.width,
          height: msr.height,
        ),
      ),
    );

    return _buildGenericDragTarget(
      child: dragTargetChild,
      tokenLine: tokenLine,
      token: token,
      tokenPositions: tokenPositions,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      maxWidth: maxWidth,
      lineHeight: lineHeight,
      surfaceColor: surfaceColor,
      onSurfaceColor: onSurfaceColor,
      isEnabled: isEnabled,
      onAddChord: onAddChord,
      onRemoveChord: onRemoveChord,
    );
  }

  Widget _buildLyricDragTarget({
    required TokenLine tokenLine,
    required List<ContentToken> tokens,
    required ContentToken token,
    required TokenPositionMap tokenPositions,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double maxWidth,
    required double lineHeight,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required bool isEnabled,
    required Function(ContentToken, ContentToken) onAddChord,
    required Function(ContentToken) onRemoveChord,
  }) {
    final dragTargetChild = SizedBox(
      height: lineHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Text(token.text, style: lyricStyle),
      ),
    );

    return _buildGenericDragTarget(
      child: dragTargetChild,
      tokenLine: tokenLine,
      token: token,
      tokenPositions: tokenPositions,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      maxWidth: maxWidth,
      lineHeight: lineHeight,
      surfaceColor: surfaceColor,
      onSurfaceColor: onSurfaceColor,
      isEnabled: isEnabled,
      onAddChord: onAddChord,
      onRemoveChord: onRemoveChord,
    );
  }

  Widget _buildSpaceDragTarget({
    required TokenLine tokenLine,
    required ContentToken token,
    required Map<String, Measurements> measurements,
    required TokenPositionMap tokenPositions,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double maxWidth,
    required double lineHeight,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required bool isEnabled,
    required Function(ContentToken, ContentToken) onAddChord,
    required Function(ContentToken) onRemoveChord,
  }) {
    final dragTargetChild = SizedBox(
      width: measurements[measurementKey(' ', lyricStyle)]!.width,
      height: lineHeight,
    );

    return _buildGenericDragTarget(
      child: dragTargetChild,
      tokenLine: tokenLine,
      token: token,
      tokenPositions: tokenPositions,
      chordStyle: chordStyle,
      lyricStyle: lyricStyle,
      maxWidth: maxWidth,
      lineHeight: lineHeight,
      surfaceColor: surfaceColor,
      onSurfaceColor: onSurfaceColor,
      isEnabled: isEnabled,
      onAddChord: onAddChord,
      onRemoveChord: onRemoveChord,
    );
  }

  /// Generic drag target builder to reduce code duplication.
  /// Wraps a child widget with DragTarget functionality if enabled.
  Widget _buildGenericDragTarget({
    required Widget child,
    required ContentToken token,
    required TokenLine tokenLine,
    required TokenPositionMap tokenPositions,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double maxWidth,
    required double lineHeight,
    required Color surfaceColor,
    required Color onSurfaceColor,
    required bool isEnabled,
    required Function(ContentToken, ContentToken) onAddChord,
    required Function(ContentToken) onRemoveChord,
    bool isChordTarget = false,
  }) {
    return isEnabled
        ? DragTarget<ContentToken>(
            onAcceptWithDetails: (details) {
              onRemoveChord(details.data);
              onAddChord(details.data, token);
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                return _buildDragTargetFeedback(
                  chordStyle: chordStyle,
                  lyricStyle: lyricStyle,
                  maxWidth: maxWidth,
                  lineHeight: lineHeight,
                  surfaceColor: surfaceColor,
                  onSurfaceColor: onSurfaceColor,
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
    required Widget dragTargetChild,
    required ContentToken draggedChord,
    required ContentToken draggedToToken,
    required TokenPositionMap tokenPositions,
    required TokenLine tokenLine,
    required bool isChordTarget,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double maxWidth,
    required double lineHeight,
    required Color surfaceColor,
    required Color onSurfaceColor,
  }) {
    final chordMsr = measureText(
      text: draggedChord.text,
      style: chordStyle,
      isChordToken: false,
    );
    final lyricMsr = measureText(
      text: draggedToToken.text,
      style: lyricStyle,
      isChordToken: false,
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
              text: draggedChord.text,
              style: chordStyle,
              isChordToken: false,
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
              style: lyricStyle,
              isChordToken: false,
            ).width +
            1;
      }
      if (token.type != TokenType.preSeparator &&
          token.type != TokenType.postSeparator) {
        cutoutWidgets.add(
          Positioned(
            left: xOffset,
            bottom: TokenizationConstants.dragFeedbackCutoutPadding,
            child: Text(token.text, style: lyricStyle),
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
        child: Text(draggedChord.text, style: chordStyle),
      ),
    );

    xOffset +=
        measureText(
          text: draggedToToken.text,
          style: lyricStyle,
          isChordToken: false,
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
            child: Text(token.text, style: lyricStyle),
          ),
        );
      }

      xOffset += measureText(text: token.text, style: lyricStyle).width + 1;
    }

    final draggedToX = tokenPositions.getX(draggedToToken) ?? 0.0;

    double cutoutXOffset;
    if (draggedToX < TokenizationConstants.dragFeedbackCutoutWidth / 2) {
      // Too close to left edge - align cutout to left edge of content
      cutoutXOffset = -draggedToX;
    } else if (draggedToX >
        maxWidth - TokenizationConstants.dragFeedbackCutoutWidth / 2) {
      // Too close to right edge - align cutout to right edge of content
      cutoutXOffset =
          (maxWidth - draggedToX) -
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
          bottom: lineHeight,
          left: cutoutXOffset,
          child: Container(
            height:
                lyricMsr.size +
                chordMsr.size +
                2 * TokenizationConstants.dragFeedbackCutoutPadding,
            width: TokenizationConstants.dragFeedbackCutoutWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: onSurfaceColor,
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
}
