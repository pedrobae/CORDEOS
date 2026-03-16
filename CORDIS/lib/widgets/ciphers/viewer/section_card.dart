import 'dart:math';

import 'package:cordis/widgets/ciphers/section_badge.dart';
import 'package:cordis/widgets/ciphers/viewer/token_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';

class SectionCard extends StatelessWidget {
  final String sectionCode;
  final String sectionType;
  final String sectionText;
  final Color sectionColor;

  const SectionCard({
    super.key,
    required this.sectionType,
    required this.sectionCode,
    required this.sectionText,
    required this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width > 600
        ? max(300, MediaQuery.of(context).size.width / 4)
        : MediaQuery.of(context).size.width;

    return Consumer<LayoutSettingsProvider>(
      builder: (context, laySet, child) {
        return SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: laySet.showSectionHeaders
                  ? colorScheme.surface
                  : sectionColor.withAlpha(30),
              border: Border.all(
                color: laySet.showSectionHeaders
                    ? colorScheme.surfaceContainerHigh
                    : sectionColor,
              ),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LABEL
                  if (laySet.showSectionHeaders)
                    Row(
                      spacing: 8,
                      children: [
                        SectionBadge(
                          sectionCode: sectionCode,
                          sectionColor: sectionColor,
                        ),
                        Text(
                          sectionType.isNotEmpty
                              ? sectionType[0].toUpperCase() +
                                    sectionType.substring(1)
                              : sectionType,
                          style: textTheme.labelLarge,
                        ),
                      ],
                    ),
                  SizedBox(height: laySet.showSectionHeaders ? 8 : 0),
                  TokenView(chordPro: sectionText),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
