import 'package:cordis/providers/schedule/play_schedule_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
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
    final scroll = context.read<AutoScrollProvider>();
    final state = context.read<PlayScheduleStateProvider>();

    return Consumer2<SectionProvider, LayoutSetProvider>(
      builder: (context, sect, laySet, child) {
        final filteredStructure = _getStructureForVersion(laySet);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: filteredStructure.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.emptyStructure,
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Selector<AutoScrollProvider, int>(
                    selector: (context, provider) =>
                        provider.currentSectionIndex,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: listScrollController,
                      child: Row(
                        spacing: StructureList.spacing,
                        children: [
                          const SizedBox(),
                          ...filteredStructure.asMap().entries.map((entry) {
                            final index = entry.key;
                            final sectionCode = entry.value;
                            final section = sect.getSection(
                              widget.versionId,
                              sectionCode,
                            );
                            if (section == null) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            return _StructureSectionButton(
                              index: index,
                              sectionCode: sectionCode,
                              sectionColor: section.contentColor,
                              highlightColor: colorScheme.primary,
                              textColor: colorScheme.surface,
                              onTap: () => scroll.scrollToItemSection(
                                itemIndex: state.currentItemIndex,
                                sectionIndex: index,
                              ),
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

  List<String> _getStructureForVersion(LayoutSetProvider laySet) {
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    if (widget.versionId == null) return [];

    List<String> songStructure;
    if (widget.versionId is int) {
      songStructure =
          localVer.getVersion(widget.versionId)?.songStructure ?? [];
    } else {
      songStructure =
          cloudVer.getVersion(widget.versionId)?.songStructure ?? [];
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

class _StructureSectionButton extends StatelessWidget {
  final int index;
  final String sectionCode;
  final Color sectionColor;
  final Color highlightColor;
  final Color textColor;
  final VoidCallback onTap;

  const _StructureSectionButton({
    required this.index,
    required this.sectionCode,
    required this.sectionColor,
    required this.highlightColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Selector<AutoScrollProvider, bool>(
        selector: (context, scroll) => scroll.currentSectionIndex == index,
        builder: (context, isCurrentSection, child) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              height: StructureList.buttonWidth,
              width: StructureList.buttonWidth,
              decoration: BoxDecoration(
                color: sectionColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: isCurrentSection
                    ? Border.all(color: highlightColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  sectionCode,
                  style: TextStyle(
                    color: textColor,
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
