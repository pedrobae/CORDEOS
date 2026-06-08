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
  void Function(int, int) _onReorder(CloudVersionNote note) {
    return (oldIndex, newIndex) async {
      if (oldIndex < newIndex) newIndex--;

      await context.read<CloudVersionProvider>().update(
        note.firebaseVersionID,
        note.id,
        note.copyWith(position: newIndex),
      );
    };
  }

  void _deleteNote(int id) async {
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
              Selector<CloudVersionProvider, Map<int, CloudVersionNote>>(
                selector: (context, cloudVer) => Map.from(
                  cloudVer.getNotesOfVersion(widget.firebaseVersionID),
                ),
                builder: (context, notes, child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return _buildNoteCard(
                        note: notes.values.toList()[index],
                        key: notes.keys.toList()[index],
                      );
                    },
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
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: SelectKeySheet(
                    initialKey: widget.versionDto.overwriteKey,
                    originalKey: widget.versionDto.originalKey,
                    versionID: widget.firebaseVersionID,
                    onKeySelected: (_) {},
                    onKeySaved: (key) {
                      final cloudVer = context.read<CloudVersionProvider>();
                      cloudVer.saveKey(widget.firebaseVersionID, key);
                    },
                    showSave: true,
                  ),
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
      child:
          Selector<
            CloudVersionProvider,
            ({List<int> songStruct, Map<int, CloudVersionNote> notes})
          >(
            selector: (context, cloudVer) {
              final notes = cloudVer.getNotesOfVersion(
                widget.firebaseVersionID,
              );

              final songMap = [...widget.versionDto.songStructure];
              songMap.removeWhere((sectionID) => sectionID < 0);
              for (final note in notes.values) {
                songMap.insert(note.position, -note.id);
              }

              return (songStruct: songMap, notes: notes);
            },
            builder: (context, s, child) {
              return ReorderableListView.builder(
                proxyDecorator: (child, index, animation) =>
                    Material(type: MaterialType.transparency, child: child),
                buildDefaultDragHandles: false,
                scrollDirection: Axis.horizontal,
                onReorder: (oldIndex, newIndex) => _onReorder(
                  s.notes[-s.songStruct[oldIndex]]!,
                )(oldIndex, newIndex),
                itemCount: s.songStruct.length,
                itemBuilder: (context, index) {
                  final sectionID = s.songStruct[index];
                  return CustomReorderableDelayed(
                    key: ValueKey(
                      'ver_idx_${widget.firebaseVersionID}_sect_idx_$index',
                    ),
                    index: index,
                    delay: Duration(milliseconds: 100),
                    enabled: sectionID < 0,
                    child: (sectionID > 0)
                        ? Container(
                            margin: EdgeInsets.only(right: 4),
                            height: 44,
                            width: 42,
                            decoration: BoxDecoration(
                              color: widget
                                  .versionDto
                                  .badgesData[sectionID]!
                                  .color
                                  .withValues(alpha: .90),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Center(
                              child: Text(
                                widget.versionDto.badgesData[sectionID]!.code,
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
                                    widget
                                        .versionDto
                                        .badgesData[sectionID]!
                                        .code,
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
                                      _deleteNote(sectionID);
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
                    : '${widget.versionDto.badgesData[-key!]?.code ?? 'N'} - ${note.title}',
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
