import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/models/domain/cipher/version.dart';

import 'package:cordeos/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';

import 'package:cordeos/screens/cipher/view_cipher.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/ciphers/library/sheet_download.dart';
import 'package:cordeos/widgets/common/cloud_download_indicator.dart';

class CloudCipherCard extends StatelessWidget {
  final String versionId;

  const CloudCipherCard({super.key, required this.versionId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector<
      CloudVersionProvider,
      ({VersionDto version, bool isDownloading})
    >(
      selector: (context, cloudVer) => (
        version: cloudVer.getVersion(versionId)!,
        isDownloading: cloudVer.isDownloading(versionId),
      ),
      builder: (context, sel, child) {
        final version = sel.version;
        return GestureDetector(
          onTap: () {
            nav.push(
              () => ViewCipherScreen(
                cipherID: null,
                versionID: versionId,
                versionType: VersionType.cloud,
              ),
              showBottomNavBar: true,
            );
          },
          child: Stack(
            children: [
              Positioned(
                right: -5,
                bottom: -25,
                child: SvgPicture.asset(
                  'assets/logos/v2_simple_color_white.svg',
                  colorFilter: ColorFilter.mode(
                    colorScheme.surfaceTint,
                    BlendMode.srcIn,
                  ),
                  height: 120,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.surfaceContainerLowest),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        spacing: 2.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TITLE
                          Text(version.title, style: textTheme.titleMedium),

                          // INFO
                          Row(
                            spacing: 16.0,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.musicKey}: ${version.transposedKey ?? version.originalKey}',
                                style: textTheme.bodyMedium,
                              ),
                              version.bpm != 0
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.bpmWithPlaceholder(
                                        version.bpm.toString(),
                                      ),
                                      style: textTheme.bodyMedium,
                                    )
                                  : Text('-'),
                              version.duration > 0
                                  ? Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.durationWithPlaceholder(
                                        DateTimeUtils.formatDuration(
                                          Duration(seconds: version.duration),
                                        ),
                                      ),
                                      style: textTheme.bodyMedium,
                                    )
                                  : Text('-'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // DOWNLOAD VERSION
                    if (sel.isDownloading == true)
                      const CloudDownloadIndicator()
                    else
                      IconButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: MediaQuery.of(context).viewInsets,
                            child: DownloadVersionSheet(versionId: versionId),
                          ),
                        ),
                        icon: Icon(Icons.cloud_download),
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
}
