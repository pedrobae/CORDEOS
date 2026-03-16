import 'package:cordis/providers/schedule/play_schedule_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/providers/section_provider.dart';

import 'package:cordis/utils/section_constants.dart';

class StructureList extends StatefulWidget {
  final dynamic versionId;

  const StructureList({super.key, required this.versionId});

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
    final colorScheme = Theme.of(context).colorScheme;
    final scroll = Provider.of<AutoScrollProvider>(context);
    final state = context.read<PlayScheduleStateProvider>();

    return Consumer2<SectionProvider, LayoutSettingsProvider>(
      builder: (context, sect, laySet, child) {
        if (sect.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredStructure = _getStructureForVersion(laySet);

        return SizedBox(
          width: double.infinity,
          child: filteredStructure.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.emptyStructure,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                )
              : ValueListenableBuilder<int>(
                  valueListenable: scroll.currentSectionIndex,
                  builder: (context, scrollIndex, child) {
                    // Auto-scroll structure list to show current section
                    _scrollToIndex(scrollIndex);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: listScrollController,
                      child: Row(
                        spacing: StructureList.spacing,
                        children: [
                          const SizedBox(),
                          ...filteredStructure.asMap().entries.map((entry) {
                            final index = entry.key;
                            final sectionCode = entry.value;
                            final isCurrentSection = index == scrollIndex;
                            final section = sect.getSection(
                              widget.versionId,
                              sectionCode,
                            );
                            // Loading state
                            if (section == null) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            final color = section.contentColor;

                            return RepaintBoundary(
                              child: GestureDetector(
                                onTap: () => scroll.isVerticalMode
                                    ? scroll.scrollToItemSection(
                                        itemIndex: state.currentItemIndex,
                                        sectionIndex: index,
                                      )
                                    : scroll.scrollToSectionTabs(index),
                                child: Container(
                                  height: StructureList.buttonWidth,
                                  width: StructureList.buttonWidth,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: isCurrentSection
                                        ? Border.all(
                                            color: colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      sectionCode,
                                      style: TextStyle(
                                        color: colorScheme.surface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  List<String> _getStructureForVersion(LayoutSettingsProvider laySet) {
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    List<String> songStructure;
    if (widget.versionId is int) {
      songStructure = localVer.getVersion(widget.versionId)?.songStructure ?? [];
    } else {
      songStructure = cloudVer.getVersion(widget.versionId)?.songStructure ?? [];
    }

    return songStructure
        .where(
          (sectionCode) =>
              ((laySet.layoutFilters[LayoutFilter.annotations]! ||
                  !isAnnotation(sectionCode)) &&
              (laySet.layoutFilters[LayoutFilter.transitions]! ||
                  !isTransition(sectionCode))),
        )
        .toList();
  }
}
