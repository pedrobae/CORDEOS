import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/schedule/play_schedule_state_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/utils/section_constants.dart';
import 'package:cordis/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContentWrap extends StatefulWidget {
  final bool isCloud;

  const ContentWrap({super.key, required this.isCloud});

  @override
  State<ContentWrap> createState() => _ContentWrapState();
}

class _ContentWrapState extends State<ContentWrap> {
  @override
  Widget build(BuildContext context) {
    return Selector2<
      PlayScheduleStateProvider,
      LayoutSettingsProvider,
      (bool, int, Axis, bool, bool)
    >(
      selector: (_, state, laySet) => (
        state.isLoading,
        state.itemCount,
        laySet.wrapDirection,
        laySet.layoutFilters[LayoutFilter.annotations] ?? true,
        laySet.layoutFilters[LayoutFilter.transitions] ?? true,
      ),
      builder: (context, value, child) {
        final (_, _, wrapDirection, _, _) = value;
        final contentWidgets = _registerAndBuildContent(wrapDirection);
        return Wrap(
          direction: wrapDirection,
          runSpacing: 16,
          spacing: 16,
          children: contentWidgets,
        );
      },
    );
  }

  List<Widget> _registerAndBuildContent(Axis wrapDirection) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final state = Provider.of<PlayScheduleStateProvider>(
      context,
      listen: false,
    );
    final scroll = context.read<AutoScrollProvider>();

    final contentWidgets = <Widget>[];

    if (state.isLoading) {
      return [const Center(child: CircularProgressIndicator())];
    }
    if (state.itemCount == 0) {
      return [Center(child: Text(AppLocalizations.of(context)!.emptyPlaylist))];
    }

    for (int i = 0; i < state.itemCount; i++) {
      final item = state.getItemAt(i);

      if (item == null) {
        contentWidgets.add(const SizedBox.shrink());
        continue;
      }

      // REGISTER ITEM FOR CURRENT ITEM RECOGNIZER AND NAVIGATION
      final itemKey = scroll.registerItem(i);

      switch (item.type) {
        case PlaylistItemType.version:
          contentWidgets.addAll([
            SizedBox.shrink(key: itemKey),
            _buildHeader(
              widget.isCloud ? item.firebaseContentId : item.contentId,
            ),
            ..._buildSectionCards(
              i,
              widget.isCloud ? item.firebaseContentId : item.contentId,
            ),
            Container(
              height: wrapDirection == Axis.horizontal ? 1 : double.infinity,
              width: wrapDirection == Axis.horizontal ? double.infinity : 1,
              color: colorScheme.primary,
            ),
          ]);
          break;
        case PlaylistItemType.flowItem:
          final flow = context.read<FlowItemProvider>();
          final laySet = context.read<LayoutSettingsProvider>();

          final flowItem = flow.getFlowItem(item.contentId!);

          contentWidgets.addAll([
            SizedBox.shrink(key: itemKey),

            if (flowItem == null) ...[
              Center(child: CircularProgressIndicator()),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Text(flowItem.title, style: textTheme.titleMedium),
                  Text(
                    '${AppLocalizations.of(context)!.estimatedTime}: ${DateTimeUtils.formatDuration(flowItem.duration)}',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: colorScheme.surfaceContainerLow,
                      width: 1.2,
                    ),
                  ),
                ),
                child: Text(
                  flowItem.contentText,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    fontFamily: laySet.lyricTextStyle.fontFamily,
                  ),
                ),
              ),
              Container(
                height: wrapDirection == Axis.horizontal ? 1 : double.infinity,
                width: wrapDirection == Axis.horizontal ? double.infinity : 1,
                color: colorScheme.primary,
              ),
            ],
          ]);
          break;
      }
    }
    return contentWidgets;
  }

  Widget _buildHeader(dynamic versionID) {
    return Consumer3<
      LocalVersionProvider,
      CloudVersionProvider,
      CipherProvider
    >(
      builder: (context, localVer, cloudVer, ciph, child) {
        final textTheme = Theme.of(context).textTheme;

        String title;
        String key;
        int bpm;
        Duration duration;

        if (widget.isCloud) {
          final version = cloudVer.getVersion(versionID);
          if (version == null) return const LinearProgressIndicator();
          title = version.title;
          key = version.transposedKey ?? version.originalKey;
          bpm = version.bpm;
          duration = Duration(milliseconds: version.duration);
        } else {
          final version = localVer.getVersion(versionID);
          if (version == null) return const LinearProgressIndicator();
          final cipher = ciph.getCipher(version.cipherId);
          if (cipher == null) return const LinearProgressIndicator();
          title = cipher.title;
          key = version.transposedKey ?? cipher.musicKey;
          bpm = version.bpm;
          duration = version.duration;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(title, style: textTheme.titleMedium),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 16.0,
              children: [
                Text(
                  AppLocalizations.of(context)!.keyWithPlaceholder(key),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  AppLocalizations.of(context)!.bpmWithPlaceholder(bpm),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(duration)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSectionCards(int itemIndex, dynamic versionId) {
    final laySet = Provider.of<LayoutSettingsProvider>(context, listen: false);

    final localVer = Provider.of<LocalVersionProvider>(context, listen: false);
    final cloudVer = Provider.of<CloudVersionProvider>(context, listen: false);
    final sect = Provider.of<SectionProvider>(context, listen: false);

    List<String> songStructure;
    if (widget.isCloud) {
      final version = cloudVer.getVersion(versionId);
      if (version == null) {
        return [const Center(child: CircularProgressIndicator())];
      }
      songStructure = version.songStructure;
    } else {
      final version = localVer.getVersion(versionId);
      if (version == null) {
        return [const Center(child: CircularProgressIndicator())];
      }
      songStructure = version.songStructure;
    }

    final filteredStructure = songStructure
        .where(
          (sectionCode) =>
              ((laySet.layoutFilters[LayoutFilter.annotations]! ||
                  !isAnnotation(sectionCode)) &&
              (laySet.layoutFilters[LayoutFilter.transitions]! ||
                  !isTransition(sectionCode))),
        )
        .toList();

    final scroll = context.read<AutoScrollProvider>();

    final sectionWidgets = <Widget>[];

    for (var i = 0; i < filteredStructure.length; i++) {
      final key = scroll.registerSection(itemIndex, i);

      final code = filteredStructure[i];

      final section = widget.isCloud
          ? () {
              final sectionMap = cloudVer
                  .getVersion(versionId)!
                  .sections[code]!;
              return Section.fromFirestore(sectionMap);
            }()
          : sect.getSection(versionId, code);

      if (section == null) {
        sectionWidgets.add(const SizedBox.shrink());
        continue;
      }

      scroll.setSectionLineCount(
        itemIndex,
        i,
        section.contentText.split('\n').length,
      );

      if (isAnnotation(code)) {
        sectionWidgets.add(
          AnnotationCard(
            key: key,
            sectionText: section.contentText,
            sectionType: section.contentType,
          ),
        );
        continue;
      }

      sectionWidgets.add(
        SectionCard(
          key: key,
          index: i,
          itemIndex: itemIndex,
          sectionType: section.contentType,
          sectionCode: code,
          sectionText: section.contentText,
          sectionColor: section.contentColor,
        ),
      );
    }

    return sectionWidgets;
  }
}
