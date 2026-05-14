import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;

    final nav = context.read<NavigationProvider>();

    return Selector<
      CloudVersionProvider,
      ({VersionDto? dto, bool isDownloading})
    >(
      selector: (context, cloudVer) {
        return (
          dto: cloudVer.getVersion(versionId),
          isDownloading: cloudVer.isDownloading(versionId),
        );
      },
      builder: (context, s, child) {
        if (s.dto == null) {
          return (Center(child: CircularProgressIndicator()));
        }

        return GestureDetector(
          onTap: () {
            final token = context.read<TokenProvider>();
            nav.push(
              () => ViewCipherScreen(
                versionDto: s.dto!,
                versionType: VersionType.cloud,
              ),
              onPopCallback: () {
                token.clear();
              },
              showBottomNavBar: true,
            );
          },
          child: Stack(
            children: [
              Positioned(
                right: -5,
                bottom: -25,
                child: SvgPicture.asset(
                  'assets/logos/nh_colored_white.svg',
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
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withAlpha(128),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.only(right: 8),
                      child: Column(
                        spacing: 2.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TITLE
                          Text(s.dto!.title, style: textTheme.titleMedium),

                          // INFO
                          Row(
                            spacing: 8.0,
                            children: [
                              Text(
                                '${l10n.musicKey}: ${s.dto!.transposedKey ?? s.dto!.originalKey}',
                                style: textTheme.bodyMedium,
                              ),
                              if (s.dto!.bpm != 0)
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.bpmWithPlaceholder(s.dto!.bpm.toString()),
                                  style: textTheme.bodyMedium,
                                ),
                              Text(
                                l10n.durationWithPlaceholder(
                                  DateTimeUtils.formatDuration(
                                    Duration(seconds: s.dto!.duration),
                                  ),
                                ),
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Spacer(),

                    // DOWNLOAD VERSION
                    if (s.isDownloading == true)
                      const CloudDownloadIndicator()
                    else
                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: MediaQuery.of(context).viewInsets,
                            child: DownloadVersionSheet(versionId: versionId),
                          ),
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Icon(
                                  Icons.cloud_rounded,
                                  color: colorScheme.surface,
                                ),
                              ),
                              Positioned.fill(
                                child: Icon(Icons.cloud_download),
                              ),
                            ],
                          ),
                        ),
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
