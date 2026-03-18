import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
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

class VersionWrap extends StatelessWidget {
  final int itemIndex;
  final dynamic versionID;

  const VersionWrap({
    super.key,
    required this.itemIndex,
    required this.versionID,
  });

  @override
  Widget build(BuildContext context) {
    return Selector5<
      PlayScheduleStateProvider,
      LayoutSetProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      (Axis, Map<LayoutFilter, bool>, int, int, int)
    >(
      selector: (context, state, laySet, localVer, cloudVer, sect) => (
        laySet.wrapDirection,
        laySet.layoutFilters,
        localVer.versions.length,
        cloudVer.versions.length,
        sect.loadedVersionsCount,
      ),
      builder: (context, value, child) {
        final (wrapDirection, _, _, _, _) = value;
        return Padding(
          padding: EdgeInsets.only(
            left: wrapDirection == Axis.vertical ? 16.0 : 0.0,
            top: wrapDirection == Axis.horizontal ? 16.0 : 0.0,
          ),
          child: Wrap(
            direction: wrapDirection,
            runSpacing: 16,
            spacing: 16,
            children: _buildSectionCards(context),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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

        if (versionID is String) {
          final version = cloudVer.getVersion(versionID);
          if (version == null) return const LinearProgressIndicator();
          title = version.title;
          key = version.transposedKey ?? version.originalKey;
          bpm = version.bpm;
          duration = Duration(milliseconds: version.duration);
        } else {
          final version = localVer.getVersion(versionID);
          if (version == null) return const LinearProgressIndicator();
          final cipher = ciph.getCipher(version.cipherID);
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

  List<Widget> _buildSectionCards(BuildContext context) {
    final laySet = Provider.of<LayoutSetProvider>(context, listen: false);

    final localVer = Provider.of<LocalVersionProvider>(context, listen: false);
    final cloudVer = Provider.of<CloudVersionProvider>(context, listen: false);
    final sect = Provider.of<SectionProvider>(context, listen: false);

    if (versionID == null) return [const SizedBox.shrink()];

    List<String> songStructure;
    if (versionID is String) {
      final version = cloudVer.getVersion(versionID);
      if (version == null) {
        return [const Center(child: CircularProgressIndicator())];
      }
      songStructure = version.songStructure;
    } else {
      final version = localVer.getVersion(versionID);
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

    final sectionWidgets = <Widget>[_buildHeader()];

    for (var i = 0; i < filteredStructure.length; i++) {
      final key = scroll.registerSection(itemIndex, i);

      final code = filteredStructure[i];

      final section = versionID is String
          ? () {
              final sectionMap = cloudVer
                  .getVersion(versionID)!
                  .sections[code]!;
              return Section.fromFirestore(sectionMap);
            }()
          : sect.getSection(versionID, code);

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
