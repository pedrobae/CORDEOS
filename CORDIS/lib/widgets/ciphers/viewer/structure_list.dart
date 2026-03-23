import 'package:cordis/models/domain/cipher/section.dart';
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
  final dynamic versionID;

  const StructureList({super.key, required this.versionID});

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
    final scroll = context.read<AutoScrollProvider>();
    final state = context.read<PlayScheduleStateProvider>();

    return Selector<LayoutSetProvider, Map<LayoutFilter, bool>>(
      selector: (context, laySet) => laySet.layoutFilters,
      builder: (context, layoutFilters, child) {
        final filteredStructure = _getStructureForVersion(layoutFilters);

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

                            return _StructureSectionButton(
                              index: index,
                              versionID: widget.versionID,
                              sectionCode: sectionCode,
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

  List<String> _getStructureForVersion(Map<LayoutFilter, bool> layoutFilters) {
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    if (widget.versionID == null) return [];

    List<String> songStructure;
    if (widget.versionID is int) {
      songStructure =
          localVer.getVersion(widget.versionID)?.songStructure ?? [];
    } else {
      songStructure =
          cloudVer.getVersion(widget.versionID)?.songStructure ?? [];
    }

    return songStructure
        .where(
          (sectionCode) =>
              ((layoutFilters[LayoutFilter.annotations]! ||
                  !isAnnotation(sectionCode)) &&
              (layoutFilters[LayoutFilter.transitions]! ||
                  !isTransition(sectionCode))),
        )
        .toList();
  }
}

class _StructureSectionButton extends StatelessWidget {
  final int index;
  final dynamic versionID;
  final String sectionCode;
  final VoidCallback onTap;

  const _StructureSectionButton({
    required this.index,
    required this.versionID,
    required this.sectionCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child:
          Selector2<
            AutoScrollProvider,
            SectionProvider,
            ({Section? section, bool highlighted})
          >(
            selector: (context, scroll, section) => (
              section: section.getSection(versionID, sectionCode),
              highlighted: scroll.currentSectionIndex == index,
            ),
            builder: (context, selection, child) {
              if (selection.section == null) {
                return const SizedBox(
                  height: StructureList.buttonWidth,
                  width: StructureList.buttonWidth,
                  child: CircularProgressIndicator(),
                );
              }

              return GestureDetector(
                onTap: onTap,
                child: Container(
                  height: StructureList.buttonWidth,
                  width: StructureList.buttonWidth,
                  decoration: BoxDecoration(
                    color: selection.section!.contentColor.withValues(
                      alpha: 0.9,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: selection.highlighted
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      sectionCode,
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
