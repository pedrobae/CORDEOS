import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:cordeos/widgets/ciphers/section_badge.dart';
import 'package:cordeos/widgets/ciphers/viewer/token_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';

class SectionCard extends StatelessWidget {
  final int index;
  final int itemIndex;
  final String sectionCode;
  final String sectionType;
  final String sectionText;
  final Color sectionColor;

  const SectionCard({
    super.key,
    required this.index,
    required this.itemIndex,
    required this.sectionType,
    required this.sectionCode,
    required this.sectionText,
    required this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final tokenProv = context.read<TokenProvider>();
    final trans = context.read<TranspositionProvider>();
    final width = MediaQuery.sizeOf(context).width;

    final layoutKey = TokenCacheKey(content: sectionText, isEditMode: false);
    return Selector2<
      LayoutSetProvider,
      TranspositionProvider,
      ({bool showLyrics, bool showChords, int transposeValue})
    >(
      selector: (context, laySet, trans) => (
        showLyrics: laySet.showLyrics,
        showChords: laySet.showChords,
        transposeValue: trans.transposeValue,
      ),
      builder: (context, filter, child) {
        // PHASE 1: Ensure tokens are cached & organized for this content + filters
        layoutKey.showChords = filter.showChords;
        layoutKey.showLyrics = filter.showLyrics;
        layoutKey.transposeValue = filter.transposeValue;

        tokenProv.tokenize(layoutKey, transposeChord: trans.transposeChord);
        tokenProv.organize(layoutKey);
        return Selector<
          LayoutSetProvider,
          ({
            TextStyle lyricStyle,
            TextStyle chordStyle,
            double chordLyricSpacing,
          })
        >(
          selector: (context, laySet) => (
            lyricStyle: laySet.lyricStyle,
            chordStyle: laySet.chordStyle,
            chordLyricSpacing: laySet.chordLyricSpacing,
          ),
          builder: (context, measure, child) {
            // PHASE 2: Ensure measurements are cached for this content + style
            layoutKey.chordLyricSpacing = measure.chordLyricSpacing;

            tokenProv.measureTokens(
              chordStyle: measure.chordStyle,
              lyricStyle: measure.lyricStyle,
              key: layoutKey,
            );

            return Selector<
              LayoutSetProvider,
              ({
                double cardWidthMult,
                double letterSpacing,
                double lineSpacing,
                double lineBreakSpacing,
                double minChordSpacing,
              })
            >(
              selector: (context, laySet) {
                return (
                  cardWidthMult: laySet.cardWidthMult,
                  letterSpacing: laySet.letterSpacing,
                  lineSpacing: laySet.lineSpacing,
                  lineBreakSpacing: laySet.lineBreakSpacing,
                  minChordSpacing: laySet.minChordSpacing,
                );
              },
              builder: (context, l, child) {
                // PHASE 3: Calculate and cache widget positions based on width constraints
                layoutKey.letterSpacing = l.letterSpacing;
                layoutKey.lineSpacing = l.lineSpacing;
                layoutKey.lineBreakSpacing = l.lineBreakSpacing;
                layoutKey.minChordSpacing = l.minChordSpacing;
                layoutKey.maxWidth =
                    width * l.cardWidthMult - 16; // 16 for padding

                tokenProv.calculatePositions(
                  key: layoutKey,
                  lyricStyle: measure.lyricStyle,
                  chordStyle: measure.chordStyle,
                );
                return Selector2<
                  LayoutSetProvider,
                  ScrollProvider,
                  ({bool isCurrent, bool showSectionHeaders})
                >(
                  selector: (context, laySet, scroll) => (
                    showSectionHeaders: laySet.showSectionHeaders,
                    isCurrent:
                        (scroll.currentSectionIndex == index &&
                        (scroll.currentItemIndex == itemIndex)),
                  ),
                  builder: (context, s, child) {
                    final Color dimmedSectionColor =
                        Color.lerp(sectionColor, colorScheme.surface, 0.82) ??
                        sectionColor;

                    return Container(
                      width: width * l.cardWidthMult,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.showSectionHeaders
                            ? colorScheme.surface
                            : dimmedSectionColor,
                        border: Border.all(
                          color: s.showSectionHeaders
                              ? colorScheme.surfaceContainerHigh
                              : sectionColor,
                        ),
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: s.isCurrent
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary,
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.showSectionHeaders)
                            Row(
                              spacing: 8,
                              children: [
                                SectionBadge(
                                  sectionCode: sectionCode,
                                  sectionColor: sectionColor,
                                ),
                                Expanded(
                                  child: Text(
                                    sectionType.isNotEmpty
                                        ? sectionType[0].toUpperCase() +
                                              sectionType.substring(1)
                                        : sectionType,
                                    style: textTheme.labelLarge,
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: s.showSectionHeaders ? 8 : 0),
                          child!,
                        ],
                      ),
                    );
                  },
                  child: TokenView(
                    tokensKey: layoutKey,
                    contentColor: sectionColor,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
