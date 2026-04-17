import 'package:cordeos/utils/section_constants.dart';
import 'package:cordeos/widgets/ciphers/section_badge.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/edit_sections_state_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';

class MergeStructure extends StatefulWidget {
  final int versionID;
  final void Function(void Function())? onInit;

  const MergeStructure({super.key, required this.versionID, this.onInit});

  @override
  State<MergeStructure> createState() => _MergeStructureState();
}

class _MergeStructureState extends State<MergeStructure> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(),
        boxShadow: [
          BoxShadow(
            color: colorScheme.surfaceContainerLow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // HEADER
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.mergePlaceholder(AppLocalizations.of(context)!.section),
                  style: textTheme.titleMedium,
                ),
              ),
              // merge action
              GestureDetector(
                onTap: _merge(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(127),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.mergePlaceholder(''),
                    style: textTheme.titleSmall,
                  ),
                ),
              ),

              // cancel
              GestureDetector(
                onTap: () {
                  context
                      .read<EditSectionsStateProvider>()
                      .disableMergeOverlay();
                },
                child: Icon(Icons.close, size: 30),
              ),
            ],
          ),

          // STRUCTURE
          Container(
            padding: EdgeInsets.all(8),
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(0),
            ),
            child:
                Selector2<
                  LocalVersionProvider,
                  SectionProvider,
                  ({
                    List<int> uniqueStructure,
                    Map<int, SectionBadgeData> badgesData,
                  })
                >(
                  selector: (context, localVer, sect) {
                    final uniqueStruct = localVer
                        .getSongStructure(widget.versionID)
                        .toSet()
                        .toList();

                    final sectionTypes = <int, SectionType>{};
                    for (var key in uniqueStruct) {
                      final section = sect.getSection(
                        versionKey: widget.versionID,
                        sectionKey: key,
                      );
                      if (section != null) {
                        sectionTypes[key] = section.sectionType;
                      } else {
                        sectionTypes[key] = SectionType.unknown;
                      }
                    }

                    return (
                      uniqueStructure: uniqueStruct,
                      badgesData: getSectionBadges(sectionTypes),
                    );
                  },
                  builder: (context, s, child) {
                    return s.uniqueStructure.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.emptyStructure,
                              style: TextStyle(
                                color: colorScheme.surfaceContainerLowest,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: s.uniqueStructure.length,
                            itemBuilder: (context, index) {
                              return _buildItem(
                                index,
                                s.uniqueStructure,
                                s.badgesData,
                              );
                            },
                          );
                  },
                ),
          ),
        ],
      ),
    );
  }

  VoidCallback _merge() {
    return () {
      final state = context.read<EditSectionsStateProvider>();
      final sect = context.read<SectionProvider>();
      final localVer = context.read<LocalVersionProvider>();

      StringBuffer newContent = StringBuffer();
      bool first = true;
      for (var key in state.mergeSectionKeys) {
        final section = sect.getSection(
          versionKey: widget.versionID,
          sectionKey: key,
        );
        if (section != null) {
          newContent.writeln(section.contentText);
        }
        if (!first) {
          sect.cacheDeletion(widget.versionID, key);
          localVer.removeSectionsByKey(widget.versionID, key);
        }
        first = false;
      }

      sect.cacheUpdate(
        widget.versionID,
        state.mergeSectionKeys.first,
        newContentText: newContent.toString(),
      );

      state.disableMergeOverlay();
    };
  }

  Widget _buildItem(
    int index,
    List<int> uniqueStructure,
    Map<int, SectionBadgeData> badgesData,
  ) {
    final sectionKey = uniqueStructure[index];
    final badgeData = badgesData[sectionKey]!;
    return Selector<
      EditSectionsStateProvider,
      ({bool isTarget, bool isSelected})
    >(
      selector: (context, state) {
        return (
          isTarget: state.mergeSectionKeys.firstOrNull == sectionKey,
          isSelected: state.mergeSectionKeys.contains(sectionKey),
        );
      },
      builder: (context, s, child) {
        return Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: GestureDetector(
            onTap: () {
              context.read<EditSectionsStateProvider>().toggleMergeSection(
                sectionKey,
              );
            },
            child: SectionBadge(
              sectionBadgeData: badgeData,
              isTarget: s.isTarget,
              isSelected: s.isSelected,
            ),
          ),
        );
      },
    );
  }
}
