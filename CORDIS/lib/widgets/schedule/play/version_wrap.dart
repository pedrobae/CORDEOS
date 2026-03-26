import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/settings/layout_settings_provider.dart';
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
    return Selector4<
      LayoutSetProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider,
      ({
        Axis wrapDirection,
        Map<LayoutFilter, bool> layoutFilters,
        List<String> songStructure,
      })
    >(
      selector: (context, laySet, localVer, cloudVer, sect) => (
        wrapDirection: laySet.wrapDirection,
        layoutFilters: laySet.layoutFilters,
        songStructure: versionID is String
            ? (cloudVer.getVersion(versionID)?.songStructure ?? [])
            : (localVer.getVersion(versionID)?.songStructure ?? []),
      ),
      builder: (context, s, child) {
        return Padding(
          padding: EdgeInsets.only(
            left: s.wrapDirection == Axis.vertical ? 16.0 : 0.0,
            top: s.wrapDirection == Axis.horizontal ? 16.0 : 0.0,
          ),
          child: Wrap(
            direction: s.wrapDirection,
            runSpacing: 8,
            spacing: 8,
            children: _buildSectionCards(
              context,
              s.songStructure,
              s.layoutFilters,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final ciph = context.read<CipherProvider>();

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
  }

  List<Widget> _buildSectionCards(
    BuildContext context,
    List<String> songStructure,
    Map<LayoutFilter, bool> layoutFilters,
  ) {
    if (versionID == null) return [const SizedBox.shrink()];

    final scroll = context.read<AutoScrollProvider>();
    final sect = context.read<SectionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    final filteredStructure = songStructure
        .where(
          (sectionCode) =>
              ((layoutFilters[LayoutFilter.annotations]! ||
                  !isAnnotation(sectionCode)) &&
              (layoutFilters[LayoutFilter.transitions]! ||
                  !isTransition(sectionCode))),
        )
        .toList();

    final sectionWidgets = <Widget>[_buildHeader(context)];

    for (var i = 0; i < filteredStructure.length; i++) {
      final key = scroll.registerSection(itemIndex, i);

      final code = filteredStructure[i];

      final section =
          sect.getSection(versionID, code) ??
          (versionID is String
              ? () {
                  final sectionDto = cloudVer
                      .getVersion(versionID)
                      ?.sections[code];
                  if (sectionDto == null) return null;
                  return sectionDto.toDomain();
                }()
              : null);

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
