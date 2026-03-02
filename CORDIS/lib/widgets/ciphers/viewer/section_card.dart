import 'package:cordis/widgets/ciphers/section_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/widgets/ciphers/viewer/chordpro_view.dart';
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
    return Consumer<LayoutSettingsProvider>(
      builder: (context, layoutSettingsProvider, child) {
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;

        if (sectionText.trim().isEmpty) {
          return SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: layoutSettingsProvider.showSectionHeaders
                ? colorScheme.surface
                : sectionColor.withAlpha(30),
            border: Border.all(
              color: layoutSettingsProvider.showSectionHeaders
                  ? colorScheme.surfaceContainerHigh
                  : sectionColor,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LABEL
              if (layoutSettingsProvider.showSectionHeaders)
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
              SizedBox(
                height: layoutSettingsProvider.showSectionHeaders ? 8 : 0,
              ),
              ChordProView(
                chordPro: sectionText,
                isAnnotation: sectionCode == 'N',
              ),
            ],
          ),
        );
      },
    );
  }
}
