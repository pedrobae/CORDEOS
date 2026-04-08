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
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(0),
            ),
            child:
                Selector2<
                  EditSectionsStateProvider,
                  LocalVersionProvider,
                  ({
                    List<String> uniqueStructure,
                    List<String> mergeSectionCodes,
                  })
                >(
                  selector: (context, state, localVer) => (
                    uniqueStructure: localVer
                        .getSongStructure(widget.versionID)
                        .toSet()
                        .toList(),
                    mergeSectionCodes: state.mergeSectionCodes,
                  ),
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
                                s.mergeSectionCodes,
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
      for (var code in state.mergeSectionCodes) {
        final section = sect.getSection(widget.versionID, code);
        if (section != null) {
          newContent.writeln(section.contentText);
        }
        if (!first) {
          sect.cacheDeletion(widget.versionID, code);
          localVer.removeSectionsByCode(widget.versionID, code);
        }
        first = false;
      }

      sect.cacheContent(
        sectionCode: state.mergeSectionCodes.first,
        versionID: widget.versionID,
        content: newContent.toString(),
      );



      state.disableMergeOverlay();
    };
  }

  Widget _buildItem(
    int index,
    List<String> uniqueStructure,
    List<String> mergeSectionCodes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final sectionCode = uniqueStructure[index];
    final isTarget = mergeSectionCodes.firstOrNull == sectionCode;
    final isSelected = mergeSectionCodes.contains(sectionCode);

    return Selector<SectionProvider, Color>(
      selector: (context, sect) =>
          sect.getSection(widget.versionID, sectionCode)?.contentColor ??
          Colors.grey,
      builder: (context, color, child) => GestureDetector(
        onTap: () {
          context.read<EditSectionsStateProvider>().toggleMergeSection(sectionCode);
        },
        child: Container(
          margin: EdgeInsets.only(right: 4),
          height: 44,
          width: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .90),
            borderRadius: BorderRadius.circular(7),
            border: isSelected
                ? Border.all(
                    color: isTarget ? colorScheme.primary : colorScheme.secondary,
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
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
