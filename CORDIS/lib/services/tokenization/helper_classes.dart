import 'package:flutter/material.dart';

/// Context object to hold common styling and behavior parameters
/// for edit mode widget building, reducing parameter clutter.
class TokenBuildContext {
  /// TEXT PARAMETERS
  final TextStyle chordStyle;
  final TextStyle lyricStyle;
  final Map<String, Measurements> cache;

  /// COLOR PARAMETERS
  final Color contentColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  /// LAYOUT PARAMETERS
  final double maxWidth;

  /// EDIT MODE SPECIFIC PARAMETERS
  final bool? isEnabled;
  final VoidCallback? toggleDrag;
  final Function(List<ContentToken>, ContentToken, ContentToken)? onAddChord;
  final Function(List<ContentToken>, ContentToken, ContentToken)? onAddPrecedingChord;
  final Function(List<ContentToken>, ContentToken)? onRemoveChord;

  const TokenBuildContext({
    required this.chordStyle,
    required this.lyricStyle,
    required this.contentColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.maxWidth,
    required this.cache,
     this.isEnabled,
     this.toggleDrag,
     this.onAddChord,
     this.onAddPrecedingChord,
     this.onRemoveChord,
  });
}

/// Context object to hold common color, spacing, and layout parameters
/// for widget positioning, reducing parameter clutter.
class PositioningContext {
  /// COLOR PARAMETERS
  final Color underLineColor;

  /// SPACING PARAMETERS
  final double lineSpacing;
  final double lineBreakSpacing;
  final double chordLyricSpacing;
  final double minChordSpacing;
  final double letterSpacing;

  /// MODE PARAMETERS
  final bool isEditMode;

  /// LAYOUT PARAMETERS
  final double maxWidth;

  const PositioningContext({
    required this.underLineColor,
    required this.maxWidth,
    this.lineSpacing = 4,
    this.lineBreakSpacing = 4,
    this.chordLyricSpacing = 4,
    this.minChordSpacing = 4,
    this.letterSpacing = 1,
    this.isEditMode = false,
  });
}

class TokenizationConstants {
  /// PRECEDING TARGET
  static const double precedingTargetWidth = 24.0;

  /// CHORD TOKEN
  static const double chordTokenHeightPadding = -2;
  static const double chordTokenWidthPadding = 20.0;

  /// DRAG TARGET FEEDBACK
  static const int dragFeedbackTokensBefore = 5;
  static const int dragFeedbackTokensAfter = 10;
  static const double dragFeedbackCutoutWidth = 130.0;
  static const double dragFeedbackCutoutPadding = 4.0;

  /// CONTENT POSITIONING
  static const double contentPaddingEdit = 32.0;
  static const double contentPaddingView = 64.0;
}

class ContentToken {
  String text;
  final TokenType type;
  int? position;

  ContentToken({required this.text, required this.type, this.position});
}

enum TokenType {
  chord,
  lyric,
  space,
  newline,
  precedingChordTarget, // Token that exists when editing
  underline, // Underscore widget used to stretch a word when a chord cant fit
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

  TokenWidget({
    required this.widget,
    required this.token,
  });

  TokenType get type => token.type;
}

class PositionedWithRef {
  final Positioned positioned;
  final TokenWidget ref;

  PositionedWithRef({required this.positioned, required this.ref});
}

class ContentTokenized {
  final List<Positioned> tokens;
  final double contentHeight;

  ContentTokenized(this.tokens, this.contentHeight);
}

/// Hierarchical structures to organize tokens into lines and words.
class TokenWord {
  final List<ContentToken> tokens;

  TokenWord(this.tokens);

  bool get isEmpty => tokens.isEmpty;
  bool get isNotEmpty => tokens.isNotEmpty;

  void add(ContentToken token, int position) {
    if (position < 0 || position > tokens.length) {
      throw RangeError('Position $position is out of bounds for tokens of length ${tokens.length}');
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

  /// Records the position of a token
  void setPosition(ContentToken token, double x, double y) {
    _positions[token] = Offset(x, y);
  }

  /// Retrieves the position of a token, or null if not positioned
  Offset? getPosition(ContentToken token) {
    return _positions[token];
  }

  /// Gets the x-coordinate of a token
  double? getX(ContentToken token) {
    return _positions[token]?.dx;
  }

  /// Gets the y-coordinate of a token
  double? getY(ContentToken token) {
    return _positions[token]?.dy;
  }

  /// Check if a token has been positioned
  bool hasPosition(ContentToken token) {
    return _positions.containsKey(token);
  }

  /// Clear all positions
  void clear() {
    _positions.clear();
  }

  /// Get all positioned tokens
  Iterable<ContentToken> get positionedTokens => _positions.keys;
}
