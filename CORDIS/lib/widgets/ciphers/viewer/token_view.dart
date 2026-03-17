import 'package:cordis/providers/settings/layout_settings_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/services/tokenization/tokenization_service.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TokenView extends StatelessWidget {
  final String chordPro;

  const TokenView({super.key, required this.chordPro});

  static const _tokenizer = TokenizationService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<LayoutSetProvider, TranspositionProvider>(
      builder: (context, laySet, trans, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final content = _tokenizer.createContent(
              content: chordPro,
              posCtx: PositioningContext(
                underLineColor: colorScheme.onSurface,
                maxWidth: constraints.maxWidth,
              ),
              contentFilters: laySet.contentFilters,
              buildCtx: TokenBuildContext(
                chordStyle: laySet.chordTextStyle(colorScheme.primary),
                lyricStyle: laySet.lyricTextStyle,
                contentColor: colorScheme.onSurface,
                surfaceColor: colorScheme.surface,
                onSurfaceColor: colorScheme.onSurface,
                maxWidth: constraints.maxWidth,
                transposeChord: (chord) => trans.transposeChord(chord),
                cache: {},
              ),
            );
            return SizedBox(
              height: content.contentHeight,
              child: Stack(clipBehavior: Clip.none, children: content.tokens),
            );
          },
        );
      },
    );
  }
}
