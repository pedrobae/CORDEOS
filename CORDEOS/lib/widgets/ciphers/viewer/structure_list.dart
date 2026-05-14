import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/providers/play/play_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';

import 'package:cordeos/utils/section_type.dart';

class StructureList extends StatefulWidget {
  final VersionDto? versionDto;
  final dynamic versionID;

  const StructureList({super.key, required this.versionID, this.versionDto});

  @override
  State<StructureList> createState() => _StructureListState();

  static const double buttonWidth = 36;
  static const double spacing = 4;
}

class _StructureListState extends State<StructureList> {
  final listScrollController = ScrollController();

  @override
  void dispose() {
    listScrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!listScrollController.hasClients) return;
    if (!listScrollController.position.hasViewportDimension) return;

    const itemWidth = StructureList.buttonWidth + 2 * StructureList.spacing;
    const initialPadding = 8.0;

    // Calculate position to center button in viewport
    final targetScroll =
        (index * itemWidth + initialPadding) -
        (listScrollController.position.viewportDimension / 2 -
            StructureList.buttonWidth / 2);

    listScrollController.animateTo(
      targetScroll.clamp(0.0, listScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scroll = context.read<ScrollProvider>();
    final state = context.read<PlayStateProvider>();

    return Selector4<
      LayoutSetProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      ({List<int> songStructure, Map<int, SectionBadgeData> badgesData})
    >(
      selector: (context, laySet, localVer, cloudVer, sect) {
        final songStructure = widget.versionDto != null
            ? widget.versionDto!.songStructure
            : (widget.versionID is String
                  ? cloudVer.getVersion(widget.versionID)!.songStructure
                  : localVer.getSongStructure(widget.versionID));

        final sectionTypes = <int, SectionType>{};
        for (var key in songStructure) {
          final type = widget.versionDto != null
              ? widget.versionDto!.sections[key]?.sectionType
              : sect
                    .getSection(versionKey: widget.versionID, sectionKey: key)
                    ?.sectionType;
          if (type != null) {
            sectionTypes[key] = type;
          } else {
            sectionTypes[key] = SectionType.unknown;
          }
        }

        return (
          songStructure: songStructure,
          badgesData: getSectionBadges(sectionTypes),
        );
      },
      builder: (context, s, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: s.songStructure.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.emptyStructure,
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Selector<ScrollProvider, int>(
                    selector: (context, provider) =>
                        provider.currentSectionIndex,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: listScrollController,
                      child: Row(
                        spacing: StructureList.spacing,
                        children: [
                          const SizedBox(),
                          ...s.songStructure.asMap().entries.map((entry) {
                            final index = entry.key;
                            final sectionKey = entry.value;

                            return _StructureSectionButton(
                              index: index,
                              badgeData: s.badgesData[sectionKey]!,
                              onTap: () {
                                scroll.probeScrollToItem(
                                  state.currentItemIndex,
                                  index,
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    builder: (context, scrollIndex, child) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _scrollToIndex(scrollIndex);
                      });

                      return child!;
                    },
                  ),
          ),
        );
      },
    );
  }
}

class _StructureSectionButton extends StatelessWidget {
  final int index;
  final SectionBadgeData badgeData;
  final VoidCallback onTap;

  const _StructureSectionButton({
    required this.index,
    required this.badgeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Selector<ScrollProvider, bool>(
        selector: (context, scroll) => scroll.currentSectionIndex == index,
        builder: (context, highlighted, child) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              height: StructureList.buttonWidth,
              width: StructureList.buttonWidth,
              decoration: BoxDecoration(
                color: badgeData.color,
                borderRadius: BorderRadius.circular(6),
                border: highlighted
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  badgeData.code,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
