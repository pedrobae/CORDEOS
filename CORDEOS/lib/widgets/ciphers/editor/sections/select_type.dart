import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/edit_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectType extends StatelessWidget {
  final int versionID;
  final int? sectionKey;
  final bool isNewSection;

  const SelectType({
    super.key,
    required this.versionID,
    this.sectionKey,
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
                  for (var type in SectionType.values)
                    GestureDetector(
                      onTap: () {
                        final sect = context.read<SectionProvider>();

                        try {
                          final newKey = _upsertSection(context, type);
                          isNewSection
                              ? nav.push(
                                  () => EditSectionScreen(
                                    sectionKey: newKey,
                                    versionID: versionID,
                                    isNewSection: true,
                                  ),
                                  showBottomNavBar: true,
                                  changeDetector: () => sect.hasUnsavedChanges,
                                  onChangeDiscarded: () =>
                                      sect.loadSection(versionID, newKey),
                                  onPopCallback: () {
                                    // If there are no unsaved changes,
                                    // Pop to return to the sections tab
                                    if (!sect.hasUnsavedChanges) {
                                      nav.pop();
                                    }
                                  },
                                )
                              : nav.pop();
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
                                color: type.color,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                type.localizedLabel(context),
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

  int _upsertSection(BuildContext context, SectionType type) {
    final sect = context.read<SectionProvider>();
    if (isNewSection) {
      final newKey = sect.cacheAddSection(
        versionID,
        Section(
          contentColor: type.color,
          contentText: '',
          contentType: type.localizedLabel(context),
          key: -1,
          versionID: versionID
        ),
      );
      return newKey;
    } else {
      sect.cacheUpdate(
        versionID,
        sectionKey!,
        newContentType: type.localizedLabel(context),
        newColor: type.color,
      );
      return sectionKey!;
    }
  }
}
