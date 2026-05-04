import "package:cordeos/l10n/app_localizations.dart";
import "package:cordeos/providers/cipher/cipher_provider.dart";
import "package:cordeos/providers/navigation_provider.dart";
import "package:cordeos/providers/section/section_provider.dart";
import "package:cordeos/providers/version/local_version_provider.dart";
import "package:cordeos/utils/date_utils.dart";
import "package:cordeos/utils/section_type.dart";
import "package:cordeos/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart";
import "package:cordeos/widgets/ciphers/editor/sections/edit_section.dart";
import "package:cordeos/widgets/ciphers/editor/sections/reorderable_structure.dart";
import "package:cordeos/widgets/common/labeled_duration_picker.dart";
import "package:cordeos/widgets/common/labeled_text_field.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class ManageSheet extends StatefulWidget {
  final int versionID;
  final bool playlistMode;

  const ManageSheet({
    super.key,
    required this.versionID,
    this.playlistMode = false,
  });

  @override
  State<ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<ManageSheet> {
  void Function()? _scrollToEnd;
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final localVer = context.read<LocalVersionProvider>();
    final version = localVer.getVersion(widget.versionID);
    if (version != null) {
      _durationController.text = DateTimeUtils.formatDuration(version.duration);
      _notesController.text = version.notes ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addListeners();
    });
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _addListeners() {
    _durationController.addListener(() {
      final duration = DateTimeUtils.parseDuration(_durationController.text);
      context.read<LocalVersionProvider>().cacheUpdates(
        widget.versionID,
        duration: duration,
      );
    });
    _notesController.addListener(() {
      context.read<LocalVersionProvider>().cacheUpdates(
        widget.versionID,
        notes: _notesController.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final localVer = context.read<LocalVersionProvider>();

    return Selector2<
      LocalVersionProvider,
      SectionProvider,
      ({
        Map<int, SectionBadgeData> badgesData,
        List<int> sectionIDs,
      })
    >(
      selector: (context, localVer, sect) {
        final sections = sect.getSections(widget.versionID);

        final sectionIDs = <int>[];
        final sectionTypes = <int, SectionType>{};
        for (var section in sections.values) {
          sectionIDs.add(section.key);
          sectionTypes[section.key] = section.sectionType;
        }
        return (
          badgesData: getSectionBadges(sectionTypes),
          sectionIDs: sectionIDs,
        );
      },
      builder: (context, s, child) {
        if (s.badgesData.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.only(
            bottom: 24,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
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
                        widget.playlistMode
                            ? AppLocalizations.of(context)!.editPlaceholder(
                                AppLocalizations.of(context)!.playlistVersion,
                              )
                            : AppLocalizations.of(context)!.managePlaceholder(
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
              // VERSION METADATA
              if (widget.playlistMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 16,
                  children: [
                    Expanded(
                      child: DurationPickerField(
                        controller: _durationController,
                      ),
                    ),
                    Expanded(child: _buildKeySelector()),
                  ],
                ),

              if (widget.playlistMode)
                LabeledTextField(
                  label: '',
                  hint: AppLocalizations.of(context)!.notesHint,
                  controller: _notesController,
                ),

              // REORDERABLE STRUCTURE
              ReorderableStructure(
                versionID: widget.versionID,
                onInit: (scrollToEnd) {
                  _scrollToEnd = scrollToEnd;
                },
              ),

              // ADD SECTION BUTTONS
              Expanded(
                child: ListView(
                  children: [
                    _buildAnnotationSection(),
                    for (var key in s.sectionIDs)
                      Builder(
                        builder: (context) {
                          final badgeData = s.badgesData[key]!;

                          return GestureDetector(
                            onTap: () {
                              localVer.addSectionToStruct(
                                widget.versionID,
                                key,
                              );
                              if (_scrollToEnd != null) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _scrollToEnd!();
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: colorScheme.surfaceContainerHigh,
                                  width: 1,
                                ),
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
                                      color: badgeData.color,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${badgeData.code} - ${badgeData.type.localizedLabel(context)}',
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.shadow,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeySelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Selector2<
      LocalVersionProvider,
      CipherProvider,
      ({String? transposedKey, String originalKey})
    >(
      selector: (context, localVer, ciph) {
        final version = localVer.getVersion(widget.versionID);
        final cipher = version != null
            ? ciph.getCipher(version.cipherID)
            : null;
        return (
          transposedKey: version?.transposedKey,
          originalKey: cipher?.musicKey ?? '',
        );
      },
      builder: (context, s, child) {
        return GestureDetector(
          onTap: () {
            final localVer = context.read<LocalVersionProvider>();
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return SelectKeySheet(
                  showSave: false,
                  initialKey: s.transposedKey,
                  originalKey: s.originalKey,
                  versionID: widget.versionID,
                  onKeySelected: (key) {
                    localVer.cacheUpdates(widget.versionID, transposedKey: key);
                    localVer.saveVersion(versionID: widget.versionID);
                  },
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.transposedKey ?? s.originalKey,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnotationSection() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final sect = context.read<SectionProvider>();
    final nav = context.read<NavigationProvider>();

    final notesColor = SectionType.annotation.color;
    final notesLabel = SectionType.annotation.localizedLabel(context);

    return GestureDetector(
      onTap: () {
        final newKey = sect.cacheAddSection(
          widget.versionID,
          notesColor,
          notesLabel,
        );

        nav.push(
          () => EditSectionScreen(
            sectionKey: newKey,
            versionID: widget.versionID,
            isNewSection: true,
            canChangeType: false,
          ),
          onChangeDiscarded: () => sect.loadSection(widget.versionID, newKey),
          showBottomNavBar: true,
          changeDetector: () {
            return sect.hasUnsavedChanges;
          },
        );

        Navigator.of(context).pop();
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
            Expanded(child: Text(notesLabel, style: textTheme.bodyLarge)),
            Icon(Icons.chevron_right, color: colorScheme.shadow),
          ],
        ),
      ),
    );
  }
}
