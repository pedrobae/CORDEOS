import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/utils/section_constants.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/edit_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectType extends StatelessWidget {
  final int versionID;
  final String? sectionCode;
  final bool isNewSection;

  const SelectType({
    super.key,
    required this.versionID,
    this.sectionCode,
    this.isNewSection = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Stack(
            children: [
              // back button
              Positioned(
                left: 0,
                child: BackButton(
                  onPressed: () {
                    nav.attemptPop(context);
                  },
                ),
              ),
              // title
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.editPlaceholder(AppLocalizations.of(context)!.section),
                    style: textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.selectSectionType,
                style: textTheme.titleLarge,
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 8,
                children: [
                  for (var section in commonSectionLabels.values)
                    GestureDetector(
                      onTap: () {
                        try {
                          final newCode = _upsertSection(context, section);
                          isNewSection
                              ? nav
                                    .pushForeground(
                                      EditSectionScreen(
                                        sectionCode: newCode,
                                        versionID: versionID,
                                        isNewSection: true,
                                      ),
                                    )
                              : nav
                                    .pushForeground(
                                      EditSectionScreen(
                                        sectionCode: newCode,
                                        versionID: versionID,
                                      ),
                                    );
                        } catch (e) {
                          // Show error snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.errorMessage('', e.toString()),
                              ),
                            ),
                          );
                        }
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
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: section.color,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                section.localizedLabel(context),
                                style: textTheme.labelLarge,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.shadow,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _upsertSection(BuildContext context, SectionLabel section) {
    final sect = context.read<SectionProvider>();
    if (isNewSection) {
      final newCode = sect.cacheAddSection(
        versionID,
        section.code,
        section.color,
        section.canonicalLabel,
      );
      return newCode;
    } else {
      final newCode = sect.cacheUpdate(
        versionID,
        sectionCode!,
        newContentCode: section.code,
        newContentType: section.canonicalLabel,
        newColor: section.color,
      );

      // If the content code has changed, update the song structure accordingly
      if (sectionCode! != section.code) {
        context.read<LocalVersionProvider>().updateSectionCodeInStruct(
          versionID,
          oldCode: sectionCode!,
          newCode: newCode,
        );

        context.read<SectionProvider>().renameSectionKey(
          versionID,
          oldCode: sectionCode!,
          newCode: newCode,
        );
      }
      return newCode;
    }
  }
}
