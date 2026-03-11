import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StructureList extends StatefulWidget {
  final dynamic versionId;
  final List<String> filteredStructure;

  const StructureList({
    super.key,
    required this.versionId,
    required this.filteredStructure,
  });

  @override
  State<StructureList> createState() => _StructureListState();
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

    // Each button: 44px wide + 8px spacing = 52px per item
    // Plus initial padding of 8px
    const buttonWidth = 44.0;
    const spacing = 8.0;
    const itemWidth = buttonWidth + spacing;
    const initialPadding = 8.0;

    // Calculate position to center button in viewport
    final targetScroll =
        (index * itemWidth + initialPadding) -
        (listScrollController.position.viewportDimension / 2 - buttonWidth / 2);

    listScrollController.animateTo(
      targetScroll.clamp(0.0, listScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scroll = Provider.of<AutoScrollProvider>(context);

    return Consumer<SectionProvider>(
      builder: (context, sect, child) {
        if (sect.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SizedBox(
          width: double.infinity,
          child: widget.filteredStructure.isEmpty
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
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToIndex(scrollIndex);
                    });

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: listScrollController,
                      child: Row(
                        spacing: 8,
                        children: [
                          const SizedBox(),
                          ...widget.filteredStructure.asMap().entries.map((
                            entry,
                          ) {
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

                            if (scroll.sectionKeys[entry.key] == null) {
                              scroll.sectionKeys[entry.key] = GlobalKey();
                            }
                            return RepaintBoundary(
                              child: GestureDetector(
                                onTap: () => scroll.scrollToSection(index),
                                child: Container(
                                  height: 44,
                                  width: 44,
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
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
