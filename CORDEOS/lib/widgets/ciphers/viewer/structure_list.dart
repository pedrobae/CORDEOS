import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/providers/playlist/play_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/auto_scroll_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/providers/section_provider.dart';

import 'package:cordeos/utils/section_constants.dart';

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
    final scroll = context.read<ScrollProvider>();
    final state = context.read<PlayStateProvider>();

    return Selector3<
      LayoutSetProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      ({List<String> filteredStructure, bool tapEnabled})
    >(
      selector: (context, laySet, localVer, cloudVer) {
        final tapEnabled = laySet.showRepeatSections == true;

        if (widget.versionID == null) {
          return (filteredStructure: [], tapEnabled: tapEnabled);
        }

        final songStructure = widget.versionID is String
            ? cloudVer.getVersion(widget.versionID)!.songStructure
            : localVer.getSongStructure(widget.versionID);

        final filteredStructure = <String>[];
        for (var code in songStructure) {
          if (laySet.showAnnotations == false && isAnnotation(code)) {
            continue;
          }
          if (laySet.showTransitions == false && isTransition(code)) {
            continue;
          }
          filteredStructure.add(code);
        }

        return (filteredStructure: filteredStructure, tapEnabled: tapEnabled);
      },
      builder: (context, s, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: s.filteredStructure.isEmpty
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
                          ...s.filteredStructure.asMap().entries.map((entry) {
                            final index = entry.key;
                            final sectionCode = entry.value;

                            return _StructureSectionButton(
                              index: index,
                              versionID: widget.versionID,
                              sectionCode: sectionCode,
                              onTap: () {
                                if (s.tapEnabled) {
                                  scroll.probeScrollToItem(state.currentItemIndex, index);
                                } else {
                                  scroll.currentSectionIndex = index;
                                }
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
            ScrollProvider,
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
