import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StructureList extends StatefulWidget {
  final dynamic versionId;
  final List<String> filteredStructure;
  final ScrollController scrollController;

  const StructureList({
    super.key,
    required this.versionId,
    required this.filteredStructure,
    required this.scrollController,
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

  void _scrollStructureListToIndex(int index) {
    if (!listScrollController.hasClients) return;

    // Each button: 44px wide + 8px spacing = 52px per item
    // Plus initial padding of 8px
    const buttonWidth = 44.0;
    const spacing = 8.0;
    const itemWidth = buttonWidth + spacing;
    const initialPadding = 8.0;

    // Calculate position to center button in viewport
    final targetScroll = (index * itemWidth + initialPadding) -
        (listScrollController.position.viewportDimension / 2 -
            buttonWidth / 2);

    listScrollController.animateTo(
      targetScroll.clamp(0.0, listScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer3<
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider
    >(
      builder:
          (
            context,
            localVersionProvider,
            cloudVersionProvider,
            sectionProvider,
            child,
          ) {
            final scrollProvider = Provider.of<AutoScrollProvider>(context, listen: false);
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
                      valueListenable: scrollProvider.currentSectionIndex,
                      builder: (context, currentIndex, child) {
                        // Auto-scroll structure list to show current section
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollStructureListToIndex(currentIndex);
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
                                final isCurrentSection = index == currentIndex;
                                final section = (widget.versionId is int)
                                    ? sectionProvider.getSection(
                                        widget.versionId,
                                        sectionCode,
                                      )
                                    : (cloudVersionProvider.getVersion(
                                                widget.versionId,
                                              ) !=
                                              null
                                          ? Section.fromFirestore(
                                              cloudVersionProvider
                                                  .getVersion(
                                                      widget.versionId)!
                                                  .sections[sectionCode]!,
                                            )
                                          : null);

                                // Loading state
                                if (section == null ||
                                    sectionProvider.isLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                }
                                final color = section.contentColor;

                                if (scrollProvider.sectionKeys[entry.key] ==
                                    null) {
                                  scrollProvider.sectionKeys[entry.key] =
                                      GlobalKey();
                                }
                                return RepaintBoundary(
                                  child: GestureDetector(
                                    onTap: () =>
                                        scrollProvider.scrollToSection(index),
                                    child: Container(
                                      height: 44,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                            alpha:  0.9),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: isCurrentSection
                                            ? Border.all(
                                                color: colorScheme.primary,
                                                width: 1,
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
