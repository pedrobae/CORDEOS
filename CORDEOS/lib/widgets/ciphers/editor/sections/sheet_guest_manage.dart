import "package:cordeos/l10n/app_localizations.dart";

import "package:cordeos/models/dtos/version_dto.dart";
import "package:cordeos/providers/version/cloud_version_provider.dart";
import "package:cordeos/widgets/ciphers/editor/sections/edit_cloud_note_screen.dart";
import "package:cordeos/widgets/common/custom_reorderable_delayed.dart";

import "package:provider/provider.dart";
import "package:cordeos/providers/navigation_provider.dart";

import "package:cordeos/utils/section_type.dart";

import "package:cordeos/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart";

import "package:flutter/material.dart";

class GuestManageSheet extends StatefulWidget {
  final VersionDto versionDto;
  final String firebaseVersionID;

  const GuestManageSheet({
    super.key,
    required this.firebaseVersionID,
    required this.versionDto,
  });

  @override
  State<GuestManageSheet> createState() => _GuestManageSheetState();
}

class _GuestManageSheetState extends State<GuestManageSheet> {
  Map<int, CloudVersionNote> notes = {};
  List<int> songStruct = [];

  @override
  void initState() {
    final cloudVer = context.read<CloudVersionProvider>();
    notes = cloudVer.getNotesOfVersion(widget.firebaseVersionID);
    songStruct.addAll(widget.versionDto.songStructure);
    setState(() {});
    super.initState();
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final key = songStruct.removeAt(oldIndex);
    songStruct.insert(newIndex, key);
    setState(() {});

    final note = notes[-key];

    if (note != null)
      await context.read<CloudVersionProvider>().update(
        -key,
        note.copyWith(position: newIndex),
      );
  }

  void _deleteNote(int id) async {
    songStruct.remove(id);
    notes.remove(-id);
    setState(() {});
    await context.read<CloudVersionProvider>().delete(
      widget.firebaseVersionID,
      -id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.managePlaceholder(
                      AppLocalizations.of(context)!.songStructure,
                    ),
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.topRight,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),

          _buildKeySelector(),

          _buildReorderableNotes(),

          Column(
            spacing: 8,
            children: [
              _buildNoteCard(),
              ListView.builder(
                shrinkWrap: true,
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return _buildNoteCard(
                    note: notes.values.toList()[index],
                    key: notes.keys.toList()[index],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeySelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.musicKey,
            style: textTheme.labelLarge,
          ),
        ),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return SelectKeySheet(
                  initialKey: widget.versionDto.overwriteKey,
                  originalKey: widget.versionDto.originalKey,
                  versionID: widget.firebaseVersionID,
                  onKeySelected: (_) {},
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              spacing: 24,
              children: [
                Selector<CloudVersionProvider, String>(
                  selector: (context, cloudVer) =>
                      cloudVer.checkOverwriteKey(widget.firebaseVersionID) ??
                      widget.versionDto.originalKey,
                  builder: (context, key, child) => Text(
                    key,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableNotes() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ReorderableListView.builder(
        proxyDecorator: (child, index, animation) =>
            Material(type: MaterialType.transparency, child: child),
        buildDefaultDragHandles: false,
        scrollDirection: Axis.horizontal,
        onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex),
        itemCount: songStruct.length,
        itemBuilder: (context, index) {
          final id = songStruct[index];
          return CustomReorderableDelayed(
            key: ValueKey(
              'ver_idx_${widget.firebaseVersionID}_sect_idx_$index',
            ),
            index: index,
            delay: Duration(milliseconds: 100),
            enabled: id < 0,
            child: (id > 0)
                ? Container(
                    margin: EdgeInsets.only(right: 4),
                    height: 44,
                    width: 42,
                    decoration: BoxDecoration(
                      color: widget.versionDto.badgesData[id]!.color.withValues(
                        alpha: .90,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        widget.versionDto.badgesData[id]!.code,
                        style: TextStyle(
                          color: colorScheme.surface,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: SectionType.annotation.color.withValues(
                        alpha: .90,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    margin: EdgeInsets.only(right: 4),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Center(
                          child: Text(
                            widget.versionDto.badgesData[id]!.code,
                            style: TextStyle(
                              color: colorScheme.surface,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: () {
                              _deleteNote(id);
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.red,
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
                  ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard({CloudVersionNote? note, int? key}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    final notesColor = SectionType.annotation.color;
    final notesLabel = SectionType.annotation.localizedLabel(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        nav.push(
          () => CloudNoteScreen(
            firebaseVersionID: widget.firebaseVersionID,
            note: note,
          ),
          showBottomNavBar: true,
          changeDetector: () {
            return true;
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colorScheme.surfaceContainerHigh, width: 1),
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notesColor,
              ),
            ),
            Expanded(
              child: Text(
                note == null
                    ? AppLocalizations.of(context)!.newPlaceholder(notesLabel)
                    : '${widget.versionDto.badgesData[-key!]?.code} - ${note.title}',
                style: textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.shadow),
          ],
        ),
      ),
    );
  }
}
