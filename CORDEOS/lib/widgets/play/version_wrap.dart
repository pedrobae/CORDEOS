import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordeos/widgets/ciphers/viewer/section_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VersionWrap extends StatelessWidget {
  final int itemIndex;
  final VersionDto? versionDto;
  final int? versionID;

  const VersionWrap({
    super.key,
    required this.itemIndex,
    required this.versionID,
    this.versionDto,
  });

  @override
  Widget build(BuildContext context) {
    return Selector5<
      LayoutSetProvider,
      TranspositionProvider,
      CipherProvider,
      LocalVersionProvider,
      SectionProvider,
      ({
        Axis wrapDirection,
        List<int> filteredStructure,
        Map<int, SectionBadgeData> badgesData,
        String originalKey,
        String? newKey,
      })
    >(
      selector: (context, laySet, trans, ciph, localVer, sect) {
        String originalKey;
        String? newKey;
        List<int> songStructure;
        if (versionDto != null) {
          originalKey = versionDto!.originalKey;
          newKey = versionDto!.transposedKey;
          songStructure = versionDto!.songStructure;
        } else {
          final version = localVer.getVersion(versionID!)!;
          originalKey = ciph.getCipher(version.cipherID)!.musicKey;
          newKey = localVer.getVersion(versionID!)!.transposedKey;
          songStructure = localVer.getSongStructure(versionID!);
        }

        final filteredStructure = <int>[];
        for (var key in songStructure) {
          final sectionType = sect
              .getSection(versionKey: versionID, sectionKey: key)
              ?.sectionType;

          if (laySet.showAnnotations == false &&
              sectionType == SectionType.annotation) {
            continue;
          }
          if (laySet.showTransitions == false && isTransition(sectionType)) {
            continue;
          }
          if (laySet.showRepeatSections == false &&
              filteredStructure.contains(key)) {
            continue;
          }
          filteredStructure.add(key);
        }

        final sectionTypes = <int, SectionType>{};
        for (var key in filteredStructure) {
          final sectionType = versionDto != null
              ? versionDto!.sections[key]?.sectionType
              : sect
                    .getSection(versionKey: versionID, sectionKey: key)
                    ?.sectionType;

          if (sectionType != null) {
            sectionTypes[key] = sectionType;
          } else {
            sectionTypes[key] = SectionType.unknown;
          }
        }

        return (
          wrapDirection: laySet.wrapDirection,
          filteredStructure: filteredStructure,
          badgesData: getSectionBadges(sectionTypes),
          originalKey: originalKey,
          newKey: newKey,
        );
      },
      builder: (context, s, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            _buildHeader(context),
            Expanded(
              flex: s.wrapDirection == Axis.vertical ? 1 : 0,
              child: Wrap(
                direction: s.wrapDirection,
                crossAxisAlignment: WrapCrossAlignment.start,
                alignment: WrapAlignment.start,
                runSpacing: 8,
                spacing: 8,
                children: _buildSectionCards(
                  context,
                  s.filteredStructure,
                  s.badgesData,
                  s.originalKey,
                  s.newKey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Selector2<
      CipherProvider,
      LocalVersionProvider,
      ({String? title, String? key, int? bpm, Duration? duration})
    >(
      selector: (context, ciph, localVer) {
        String? title;
        String? key;
        int? bpm;
        Duration? duration;
        if (versionDto != null) {
          title = versionDto!.title;
          key = versionDto!.transposedKey ?? versionDto!.originalKey;
          bpm = versionDto!.bpm;
          duration = Duration(seconds: versionDto!.duration);
        } else {
          final version = localVer.getVersion(versionID!);
          if (version == null) {
            return (title: null, key: null, bpm: null, duration: null);
          }
          final cipher = ciph.getCipher(version.cipherID);
          title = cipher?.title;
          key = version.transposedKey ?? cipher?.musicKey;
          bpm = version.bpm;
          duration = version.duration;
        }
        return (title: title, key: key, bpm: bpm, duration: duration);
      },
      builder: (context, s, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.title ?? '', style: textTheme.titleMedium),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 16.0,
              children: [
                Text(
                  AppLocalizations.of(context)!.keyWithPlaceholder(s.key ?? ''),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  AppLocalizations.of(context)!.bpmWithPlaceholder(s.bpm ?? 0),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  '${AppLocalizations.of(context)!.duration}: ${DateTimeUtils.formatDuration(s.duration ?? Duration.zero)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSectionCards(
    BuildContext context,
    List<int> filteredStructure,
    Map<int, SectionBadgeData> badgesData,
    String originalKey,
    String? newKey,
  ) {

    final scroll = context.read<ScrollProvider>();
    final sect = context.read<SectionProvider>();
    final trans = context.read<TranspositionProvider>();

    final sectionWidgets = <Widget>[];

    for (var i = 0; i < filteredStructure.length; i++) {
      final key = scroll.registerSection(itemIndex, i);

      final sectionKey = filteredStructure[i];

      final section = versionDto != null
          ? versionDto!.sections[sectionKey]?.toDomain()
          : sect.getSection(versionKey: versionID, sectionKey: sectionKey);

      if (section == null) {
        debugPrint(
          "VERSION WRAP - couldnt get section data, probably cloud not being loaded",
        );
        sectionWidgets.add(const SizedBox.shrink());
        continue;
      }

      scroll.setSectionLineCount(
        itemIndex,
        i,
        section.contentText.split('\n').length,
      );

      if (section.sectionType == SectionType.annotation) {
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
        RepaintBoundary(
          child: SectionCard(
            key: key,
            index: i,
            itemIndex: itemIndex,
            sectionType: section.contentType,
            sectionKey: sectionKey,
            sectionText: section.contentText,
            sectionBadge: badgesData[sectionKey]!,
            transposeChord: (chord) =>
                trans.transposeChord(chord, originalKey, newKey),
          ),
        ),
      );
    }

    return sectionWidgets;
  }
}
