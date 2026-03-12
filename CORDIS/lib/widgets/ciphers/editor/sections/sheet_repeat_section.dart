import "package:cordis/l10n/app_localizations.dart";
import "package:cordis/providers/section_provider.dart";
import "package:cordis/providers/version/local_version_provider.dart";
import "package:cordis/widgets/common/filled_text_button.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class RepeatSectionSheet extends StatelessWidget {
  final int versionID;
  const RepeatSectionSheet({super.key, required this.versionID});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final localVer = context.read<LocalVersionProvider>();

    final songStructure = localVer.getVersion(versionID)!.songStructure;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.duplicatePlaceholder(
                        AppLocalizations.of(context)!.section,
                      ),
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      AppLocalizations.of(context)!.duplicateSectionInstruction,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.shadow,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.topRight,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),

            // EXISTING SECTIONS
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var sectionCode in songStructure.toSet())
                  Builder(
                    builder: (context) {
                      final sect = context.read<SectionProvider>();
                      final section = sect.getSection(versionID, sectionCode)!;
                      return GestureDetector(
                        onTap: () {
                          localVer.addSectionToStruct(versionID, sectionCode);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colorScheme.surfaceContainerHigh,
                              width: 1,
                            ),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: section.contentColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  section.contentCode,
                                  style: textTheme.bodyLarge,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: colorScheme.shadow,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),

            FilledTextButton(
              text: AppLocalizations.of(context)!.cancel,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            SizedBox(),
          ],
        ),
      ),
    );
  }
}
