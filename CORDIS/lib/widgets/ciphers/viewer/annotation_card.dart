import 'dart:math';

import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnnotationCard extends StatelessWidget {
  final String sectionText;
  final String sectionType;

  const AnnotationCard({
    super.key,
    required this.sectionText,
    required this.sectionType,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width > 600
      ? max(300.0, MediaQuery.of(context).size.width / 4)
        : MediaQuery.of(context).size.width;

    return Consumer<LayoutSettingsProvider>(
      builder: (context, laySet, child) {
        if (sectionText.trim().isEmpty) {
          return SizedBox.shrink();
        }
        return SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(0),
              border: BoxBorder.fromLTRB(
                left: BorderSide(color: colorScheme.primary, width: 6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  // LABEL
                  Text(
                    sectionType.isNotEmpty
                        ? sectionType[0].toUpperCase() + sectionType.substring(1)
                        : sectionType,
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: laySet.fontSize * 1.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // CONTENT
                  Text(sectionText, style: laySet.lyricTextStyle),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
