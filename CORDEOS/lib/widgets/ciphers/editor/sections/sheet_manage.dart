import "package:cordeos/l10n/app_localizations.dart";
import "package:cordeos/models/domain/cipher/section.dart";
import "package:cordeos/providers/navigation_provider.dart";
import "package:cordeos/providers/section/section_provider.dart";
import "package:cordeos/providers/version/local_version_provider.dart";
import "package:cordeos/utils/section_type.dart";
import "package:cordeos/widgets/ciphers/editor/sections/edit_section.dart";
import "package:cordeos/widgets/ciphers/editor/sections/reorderable_structure.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class ManageSheet extends StatefulWidget {
  final int versionID;

  const ManageSheet({super.key, required this.versionID});

  @override
  State<ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<ManageSheet> {
  void Function()? _scrollToEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final localVer = context.read<LocalVersionProvider>();

    return Selector2<
      LocalVersionProvider,
      SectionProvider,
      ({Map<int, SectionBadgeData> badgesData, List<int> sectionIDs})
    >(
      selector: (context, localVer, sect) {
        final sections = sect.getSections(widget.versionID);
        final songStruct = localVer.getSongStructure(widget.versionID);

        final sectionIDs = <int>[];
        final sectionTypes = <int, SectionType>{};
        for (final key in songStruct) {
          if (!sectionIDs.contains(key)) {
            sectionIDs.add(key);
            sectionTypes[key] =
                sections[key]?.sectionType ?? SectionType.unknown;
          }
        }

        for (final section in sections.values) {
          if (!sectionIDs.contains(section.key)) {
            sectionIDs.add(section.key);
            sectionTypes[section.key] = section.sectionType;
          }
        }

        return (
          badgesData: getSectionBadges(sectionTypes),
          sectionIDs: sectionIDs,
        );
      },
      builder: (context, s, child) {
        if (s.badgesData.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(0),
            ),
            padding: const EdgeInsets.only(
              bottom: 24,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              spacing: 16,
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
                          l10n.managePlaceholder(l10n.songStructure),
                          style: textTheme.titleMedium,
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

                // REORDERABLE STRUCTURE
                ReorderableStructure(
                  versionID: widget.versionID,
                  onInit: (scrollToEnd) {
                    _scrollToEnd = scrollToEnd;
                  },
                ),

                // ADD SECTION BUTTONS
                Expanded(
                  child: ListView(
                    children: [
                      _buildAnnotationSection(),
                      for (var key in s.sectionIDs)
                        Builder(
                          builder: (context) {
                            final badgeData = s.badgesData[key]!;

                            return GestureDetector(
                              onTap: () {
                                localVer.addSectionToStruct(
                                  widget.versionID,
                                  key,
                                );
                                if (_scrollToEnd != null) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _scrollToEnd!();
                                  });
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
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: badgeData.color,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${badgeData.code} - ${badgeData.type.localizedLabel(context)}',
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnotationSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final sect = context.read<SectionProvider>();
    final nav = context.read<NavigationProvider>();

    final notesColor = SectionType.annotation.color;
    final notesLabel = SectionType.annotation.localizedLabel(context);

    return GestureDetector(
      onTap: () {
        final newKey = sect.cacheAddSection(
          widget.versionID,
          Section(
            key: -1,
            versionID: widget.versionID,
            contentType: notesLabel,
            contentText: '',
            contentColor: notesColor,
          ),
        );

        nav.push(
          () => EditSectionScreen(
            sectionKey: newKey,
            versionID: widget.versionID,
            isNewSection: true,
            canChangeType: false,
          ),
          onChangeDiscarded: () => sect.loadSection(widget.versionID, newKey),
          showBottomNavBar: true,
          changeDetector: () {
            return sect.hasUnsavedChanges;
          },
        );

        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colorScheme.surfaceContainerHigh, width: 1),
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
                color: notesColor,
              ),
            ),
            Expanded(child: Text(notesLabel, style: textTheme.bodyLarge)),
            Icon(Icons.chevron_right, color: colorScheme.shadow),
          ],
        ),
      ),
    );
  }
}
