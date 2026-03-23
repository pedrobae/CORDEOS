import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordis/widgets/common/custom_reorderable_delayed.dart';
import 'package:provider/provider.dart';

class ReorderableStructure extends StatelessWidget {
  final int versionID;
  const ReorderableStructure({super.key, required this.versionID});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final sect = context.read<SectionProvider>();
    final localVer = context.read<LocalVersionProvider>();

    return Selector<LocalVersionProvider, List<String>>(
      selector: (context, localVer) =>
          localVer.getVersion(versionID)?.songStructure ?? [],
      builder: (context, songStructure, child) {
        return Container(
          padding: EdgeInsets.all(8),
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(0),
          ),
          child: songStructure.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.emptyStructure,
                    style: TextStyle(color: colorScheme.surfaceContainerLowest),
                    textAlign: TextAlign.center,
                  ),
                )
              : ReorderableListView.builder(
                  proxyDecorator: (child, index, animation) =>
                      Material(type: MaterialType.transparency, child: child),
                  buildDefaultDragHandles: false,
                  scrollDirection: Axis.horizontal,
                  itemCount: songStructure.length,
                  onReorder: (oldIndex, newIndex) => localVer
                      .reorderSongStructure(versionID, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final sectionCode = songStructure[index];

                    final color =
                        sect.getSection(versionID, sectionCode)?.contentColor ??
                        Colors.grey;

                    final sectionCount = songStructure
                        .where((code) => code == sectionCode)
                        .length;

                    return CustomReorderableDelayed(
                      delay: Duration(milliseconds: 100),
                      key: ValueKey('$sectionCode-$index'),
                      index: index,

                      child: Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 4),
                            height: 44,
                            width: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .90),
                              borderRadius: BorderRadius.circular(7),
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
                          Positioned(
                            top: -3,
                            right: 1, // Right margin is 4
                            child: GestureDetector(
                              onTap: () {
                                localVer.removeSection(versionID, index);
                                if (sectionCount == 1) {
                                  sect.cacheDeletion(versionID, sectionCode);
                                }
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: colorScheme.surface,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
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
