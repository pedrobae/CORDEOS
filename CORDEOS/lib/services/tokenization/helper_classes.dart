import 'package:flutter/material.dart';

class TokenizationConstants {
  /// GENERIC TARGET
  static const double targetWidth = 24.0;

  /// CHORD TOKEN
  static const double chordTokenHeightPadding = 4;
  static const double chordTokenWidthPadding = 10.0;

  /// DRAG TARGET FEEDBACK
  static const double dragFeedbackCutoutWidth = 130.0;
  static const double dragFeedbackCutoutPadding = 4.0;
}

/// Context object to hold common styling and behavior parameters
/// for widget building, reducing parameter clutter.
class TokenBuildContext {
  /// TEXT PARAMETERS
  final TextStyle chordStyle;
  final TextStyle lyricStyle;

  /// COLOR PARAMETERS
  final Color contentColor;
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color chordTargetColor;

  /// LAYOUT PARAMETERS
  final double maxWidth;
  double? lineHeight; // calculated during layout
  double? chordHeight; // calculated during layout

  /// TRANSPOSER
  final String Function(String chord) transposeChord;

  /// EDIT MODE SPECIFIC PARAMETERS
  final bool? isEnabled;
  final VoidCallback? toggleDrag;
  final Function(ContentToken, ContentToken)? onAddChord;
  final Function(ContentToken)? onRemoveChord;

  TokenBuildContext({
    required this.chordStyle,
    required this.lyricStyle,
    required this.contentColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.chordTargetColor,
    required this.maxWidth,
    required this.transposeChord,
    this.lineHeight,
    this.isEnabled,
    this.toggleDrag,
    this.onAddChord,
    this.onRemoveChord,
  });
}

class ContentToken {
  String text;
  final TokenType type;
  int? position;

  ContentToken({this.text = '', required this.type, this.position});

  String toKey() {
    return hashCode.toString();
  }
}

enum TokenType {
  chord, // Used to render a chord widget - '[C]',
  lyric, // Used to render a lyric widget - 'Hello'
  space, // Used to render a space between words - ' '
  newline, // Used to render a line break - '\n'
  preSeparator, // Used to separate preceding chords - '<'
  postSeparator, // Used to separate following chords - '>'
  preChordTarget, // Used to render a drag Target below chord - '@'
  postChordTarget, // Variation due to on dragged to differences - &
  underline, // Underscore widget used to stretch a word when a chord cant fit - N/A
}

class Measurements {
  double width;
  double height;
  double baseline;
  double size;

  double get bottomPadding => height - baseline;

  Measurements({
    required this.width,
    required this.height,
    required this.baseline,
    required this.size,
  });

  Measurements copyWith({
    double? width,
    double? height,
    double? baseline,
    double? size,
  }) {
    return Measurements(
      width: width ?? this.width,
      height: height ?? this.height,
      baseline: baseline ?? this.baseline,
      size: size ?? this.size,
    );
  }
}

class TokenWidget {
  final Widget widget;
  final ContentToken token;

  TokenWidget({required this.widget, required this.token});

  TokenType get type => token.type;
}

class PositionedWithRef {
  final Positioned positioned;
  final TokenWidget ref;

  PositionedWithRef({required this.positioned, required this.ref});
}

class ContentTokenized {
  final List<Positioned> tokens;

  ContentTokenized(this.tokens);
}

/// Hierarchical structures to organize tokens into lines and words.
class TokenWord {
  final List<ContentToken> tokens;

  TokenWord(this.tokens);

  bool get isEmpty => tokens.isEmpty;
  bool get isNotEmpty => tokens.isNotEmpty;

  void add(ContentToken token, int position) {
    if (position < 0 || position > tokens.length) {
      throw RangeError(
        'Position $position is out of bounds for tokens of length ${tokens.length}',
      );
    }
    tokens.insert(position, token);
  }
}

class TokenLine {
  final List<TokenWord> words;

  TokenLine(this.words);

  bool get isEmpty => words.isEmpty;
  bool get isNotEmpty => words.isNotEmpty;

  /// Converts to nested list for backwards compatibility
  List<List<ContentToken>> toNestedList() {
    return words.map((word) => word.tokens).toList();
  }
}

class OrganizedTokens {
  final List<TokenLine> lines;

  OrganizedTokens(this.lines);

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  List<ContentToken> get tokens {
    final tokens = <ContentToken>[];
    for (final line in this.lines) {
      for (final word in line.words) {
        tokens.addAll(word.tokens);
      }
    }
    return tokens;
  }
}

/// Hierarchical structures to organize tokens into lines and words.
class WidgetWord {
  final List<TokenWidget> widgets;

  WidgetWord(this.widgets);

  bool get isEmpty => widgets.isEmpty;
  bool get isNotEmpty => widgets.isNotEmpty;
}

class WidgetLine {
  final List<WidgetWord> words;

  WidgetLine(this.words);

  bool get isEmpty => words.isEmpty;
  bool get isNotEmpty => words.isNotEmpty;
}

class OrganizedWidgets {
  final List<WidgetLine> lines;

  OrganizedWidgets(this.lines);

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;
}

/// Maps ContentTokens to their calculated positions (x, y coordinates).
/// Used during widget building to provide layout information that depends
/// on final positioning calculations (e.g., drag feedback positioning).
class TokenPositionMap {
  final Map<ContentToken, Offset> _positions = {};
  double? contentHeight;
  double contentWidth;
  double lineHeight;

  TokenPositionMap({required this.lineHeight, required this.contentWidth});

  /// Records the position of a token
  void setPosition(ContentToken token, double x, double y) {
    _positions[token] = Offset(x, y);
  }

  /// Gets all positions
  Map<ContentToken, Offset> get tokens => _positions;

  /// Gets the x-coordinate of a token
  double? getX(ContentToken token) {
    return _positions[token]?.dx;
  }

  /// Gets the y-coordinate of a token
  double? getY(ContentToken token) {
    return _positions[token]?.dy;
  }

  void merge(TokenPositionMap other) {
    _positions.addAll(other._positions);
  }

  // PRINT FOR DEBUGGING
  void print() {
    _positions.forEach((token, offset) {
      debugPrint(
        "Token: ${token.text} (${token.type}), Position: (${offset.dx}, ${offset.dy})",
      );
    });
  }
}

class SectionPaintModel {
  final int key;
  final List<TextPaintInstruction> textInstructions;
  final List<UnderLinePaintInstruction> underlines;
  final Size size;
  final Color underlineColor;

  SectionPaintModel({
    required this.key,
    required this.textInstructions,
    required this.underlines,
    required this.size,
    required this.underlineColor,
  });
}

class BadgePaintModel {
  final int key;
  final TextPainter textPainter;
  final TextStyle style;
  final Color color;

  BadgePaintModel({
    required this.key,
    required this.color,
    required this.style,
    required this.textPainter,
  });

  RRect get rRect {
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, textPainter.width + 8, textPainter.height + 4),
      const Radius.circular(4),
    );
  }
}

class LabelPaintModel {
  final int key;
  final TextPainter textPainter;
  final TextStyle style;

  LabelPaintModel({
    required this.key,
    required this.style,
    required this.textPainter,
  });
}

class TextPaintInstruction {
  final Offset offset;
  final TextStyle style;
  final TextPainter painter;

  TextPaintInstruction({
    required this.offset,
    required this.style,
    required this.painter,
  });
}

class UnderLinePaintInstruction {
  final Offset offset;
  final double width;

  UnderLinePaintInstruction({required this.offset, required this.width});
}
