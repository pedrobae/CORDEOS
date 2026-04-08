import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/play/auto_scroll_provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:cordeos/utils/section_constants.dart';
import 'package:cordeos/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordeos/widgets/ciphers/viewer/section_card.dart';
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
    return Selector3<
      LayoutSetProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      ({Axis wrapDirection, List<String> filteredStructure})
    >(
      selector: (context, laySet, localVer, cloudVer) {
        final songStructure = versionID is String
            ? cloudVer.getVersion(versionID)!.songStructure
            : localVer.getSongStructure(versionID);

        final filteredStructure = <String>[];
        for (var code in songStructure) {
          if (laySet.showAnnotations == false && isAnnotation(code)) {
            continue;
          }
          if (laySet.showTransitions == false && isTransition(code)) {
            continue;
          }
          if (laySet.showRepeatSections == false &&
              filteredStructure.contains(code)) {
            continue;
          }
          filteredStructure.add(code);
        }

        return (
          wrapDirection: laySet.wrapDirection,
          filteredStructure: filteredStructure,
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
                children: _buildSectionCards(context, s.filteredStructure),
              ),
            ),
          ],
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
    List<String> filteredStructure,
  ) {
    if (versionID == null) return [const SizedBox.shrink()];

    final scroll = context.read<ScrollProvider>();
    final sect = context.read<SectionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    final sectionWidgets = <Widget>[];

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
        RepaintBoundary(
          child: SectionCard(
            key: key,
            index: i,
            itemIndex: itemIndex,
            sectionType: section.contentType,
            sectionCode: code,
            sectionText: section.contentText,
            sectionColor: section.contentColor,
          ),
        ),
      );
    }

    return sectionWidgets;
  }
}
