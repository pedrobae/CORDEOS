import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/utils/section_constants.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/widgets/common/custom_reorderable_delayed.dart';
import 'package:provider/provider.dart';

class ReorderableStructure extends StatefulWidget {
  final int versionID;
  final bool showDelete;
  final void Function(void Function())? onInit;

  const ReorderableStructure({
    super.key,
    required this.versionID,
    this.showDelete = true,
    this.onInit,
  });

  @override
  State<ReorderableStructure> createState() => _ReorderableStructureState();
}

class _ReorderableStructureState extends State<ReorderableStructure> {
  final _scrollController = ScrollController();

  void scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.onInit != null) {
      widget.onInit!(scrollToEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final localVer = context.read<LocalVersionProvider>();

    return Selector2<
      LocalVersionProvider,
      SectionProvider,
      ({List<int> songStructure, Map<int, SectionBadgeData> badgesData})
    >(
      selector: (context, localVer, sect) {
        final songStruct = localVer.getSongStructure(widget.versionID);

        final sectionTypes = <int, SectionType>{};
        for (var key in songStruct) {
          final type = sect
              .getSection(versionKey: widget.versionID, sectionKey: key)
              ?.sectionType;
          if (type != null) {
            sectionTypes[key] = type;
          } else {
            sectionTypes[key] = SectionType.unknown;
          }
        }

        return (
          songStructure: songStruct,
          badgesData: getSectionBadges(sectionTypes),
        );
      },
      builder: (context, s, child) {
        return Container(
          padding: EdgeInsets.all(8),
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(0),
          ),
          child: s.songStructure.isEmpty
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
                  scrollController: _scrollController,
                  itemCount: s.songStructure.length,
                  onReorder: (oldIndex, newIndex) =>
                      localVer.reorderSongStructure(
                        widget.versionID,
                        oldIndex,
                        newIndex,
                      ),
                  itemBuilder: (context, index) {
                    return _buildItem(
                      context,
                      index,
                      s.songStructure,
                      s.badgesData,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    List<int> songStructure,
    Map<int, SectionBadgeData> badgesData,
  ) {
    final sect = context.read<SectionProvider>();
    final localVer = context.read<LocalVersionProvider>();

    final colorScheme = Theme.of(context).colorScheme;

    final sectionKey = songStructure[index];
    final badgeData = badgesData[sectionKey]!;

    final codeCount = songStructure.where((code) => code == sectionKey).length;

    return CustomReorderableDelayed(
      delay: Duration(milliseconds: 100),
      key: ValueKey('$sectionKey-$index'),
      index: index,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(right: 4),
            height: 44,
            width: 42,
            decoration: BoxDecoration(
              color: badgeData.color.withValues(alpha: .90),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                badgeData.code,
                style: TextStyle(
                  color: colorScheme.surface,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (widget.showDelete)
            Positioned(
              top: -3,
              right: 1, // Right margin is 4
              child: GestureDetector(
                onTap: () {
                  debugPrint("REORDERABLE CHIP - tapped delete button");
                  localVer.removeSection(widget.versionID, index);
                  if (codeCount == 1) {
                    sect.cacheDeletion(widget.versionID, sectionKey);
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
  }
}
