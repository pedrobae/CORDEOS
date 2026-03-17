import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/widgets/ciphers/section_badge.dart';
import 'package:cordis/widgets/ciphers/viewer/token_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';

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
    final width = MediaQuery.of(context).size.width;

    return Selector2<
      LayoutSetProvider,
      AutoScrollProvider,
      ({bool isCurrent, bool showSectionHeaders, double cardWidthMult})
    >(
      selector: (context, laySet, scroll) => (
        showSectionHeaders: laySet.showSectionHeaders,
        isCurrent:
            (scroll.currentSectionIndex == index &&
            (scroll.currentItemIndex == itemIndex)),
        cardWidthMult: laySet.cardWidthMult,
      ),
      child: TokenView(chordPro: sectionText),
      builder: (context, selection, child) {
        final showSectionHeaders = selection.showSectionHeaders;
        final Color dimmedSectionColor =
            Color.lerp(sectionColor, colorScheme.surface, 0.82) ?? sectionColor;

        return SizedBox(
          width: width * selection.cardWidthMult,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: showSectionHeaders
                  ? colorScheme.surface
                  : dimmedSectionColor,
              border: Border.all(
                color: showSectionHeaders
                    ? colorScheme.surfaceContainerHigh
                    : sectionColor,
              ),
              borderRadius: BorderRadius.circular(0),
              boxShadow: selection.isCurrent
                  ? [BoxShadow(color: colorScheme.primary, blurRadius: 8)]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSectionHeaders)
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
                  SizedBox(height: showSectionHeaders ? 8 : 0),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
