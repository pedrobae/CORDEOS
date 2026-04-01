import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/services/tokenization/tokenization_service.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TokenView extends StatefulWidget {
  final String chordPro;

  const TokenView({super.key, required this.chordPro});

  @override
  State<TokenView> createState() => _TokenViewState();
}

class _TokenViewState extends State<TokenView> {
  static const _tokenizer = TokenizationService();

  // Memoize the last built content so createContent() (TextPainter layout) only
  // runs when something actually changes, not on every provider notification.
  ContentTokenized? _cachedContent;
  String? _cacheKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Selector2<
      LayoutSetProvider,
      TranspositionProvider,
      ({
        // Scalar values only — no method tear-offs (always unequal in Dart) and
        // no Map instances (reference equality). This ensures the selector only
        // triggers a rebuild when a value genuinely changes.
        String? transposedKey,
        double lineSpacing,
        double lineBreakSpacing,
        double chordLyricSpacing,
        double minChordSpacing,
        double letterSpacing,
        TextStyle chordStyle,
        TextStyle lyricStyle,
        bool showChords,
        bool showLyrics,
      })
    >(
      selector: (context, laySet, trans) {
        return (
          transposedKey: trans.transposedKey,
          lineSpacing: laySet.lineSpacing,
          lineBreakSpacing: laySet.lineBreakSpacing,
          chordLyricSpacing: laySet.chordLyricSpacing,
          minChordSpacing: laySet.minChordSpacing,
          letterSpacing: laySet.letterSpacing,
          chordStyle: laySet.chordTextStyle(colorScheme.primary),
          lyricStyle: laySet.lyricTextStyle,
          showChords: laySet.showChords,
          showLyrics: laySet.showLyrics,
        );
      },
      builder: (context, s, child) {
        // Access the transposer via read() — safe inside builder, not watch().
        final transposeChord =
            context.read<TranspositionProvider>().transposeChord;
        return LayoutBuilder(
          builder: (context, constraints) {
            // Build a cache key from every input that affects tokenization layout.
            final cacheKey =
                '${widget.chordPro}'
                '|${constraints.maxWidth.toStringAsFixed(1)}'
                '|${s.transposedKey}'
                '|${s.lineSpacing}|${s.lineBreakSpacing}'
                '|${s.chordLyricSpacing}|${s.minChordSpacing}'
                '|${s.letterSpacing}'
                '|${s.showChords}|${s.showLyrics}'
                '|${s.chordStyle.fontSize}|${s.chordStyle.fontFamily}'
                '|${colorScheme.primary.value}|${colorScheme.onSurface.value}';

            if (cacheKey == _cacheKey && _cachedContent != null) {
              return SizedBox(
                height: _cachedContent!.contentHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: _cachedContent!.tokens,
                ),
              );
            }

            _cacheKey = cacheKey;
            _cachedContent = _tokenizer.createContent(
              content: widget.chordPro,
              posCtx: PositioningContext(
                underLineColor: colorScheme.onSurface,
                maxWidth: constraints.maxWidth,
                lineSpacing: s.lineSpacing,
                lineBreakSpacing: s.lineBreakSpacing,
                chordLyricSpacing: s.chordLyricSpacing,
                minChordSpacing: s.minChordSpacing,
                letterSpacing: s.letterSpacing,
                isEditMode: false,
              ),
              contentFilters: {
                ContentFilter.chords: s.showChords,
                ContentFilter.lyrics: s.showLyrics,
              },
              buildCtx: TokenBuildContext(
                chordStyle: s.chordStyle,
                lyricStyle: s.lyricStyle,
                contentColor: colorScheme.onSurface,
                surfaceColor: colorScheme.surface,
                onSurfaceColor: colorScheme.onSurface,
                chordTargetColor: colorScheme.surfaceTint,
                maxWidth: constraints.maxWidth,
                transposeChord: transposeChord,
                cache: {},
              ),
            );

            return SizedBox(
              height: _cachedContent!.contentHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: _cachedContent!.tokens,
              ),
            );
          },
        );
      },
    );
  }
}
