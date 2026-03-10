import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/screens/cipher/view_cipher.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/ciphers/library/sheet_download.dart';
import 'package:cordis/widgets/common/cloud_download_indicator.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/selection_provider.dart';

class CloudCipherCard extends StatelessWidget {
  final String versionId;

  const CloudCipherCard({super.key, required this.versionId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Consumer2<CloudVersionProvider, SelectionProvider>(
      builder: (context, cloudVer, sel, child) {
        final version = cloudVer.getVersion(versionId)!;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerLowest),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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

                        // CLOUD DETAIL
                        Text(
                          AppLocalizations.of(context)!.cloudCipher,
                          style: textTheme.bodyMedium!.copyWith(
                            color: colorScheme.shadow,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DOWNLOAD VERSION
                  if (cloudVer.isDownloading(versionId) == true)
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

              // VIEW BUTTON
              FilledTextButton(
                text: (sel.isSelectionMode)
                    ? AppLocalizations.of(context)!.addToPlaylist
                    : AppLocalizations.of(context)!.viewPlaceholder(''),
                isDense: true,
                onPressed: () {
                  final localVer = context.read<LocalVersionProvider>();

                  if (sel.isSelectionMode) {
                    sel.select(versionId);

                    nav.push(
                      () => EditCipherScreen(
                        versionType: VersionType.playlist,
                        isEnabled: false,
                        versionID: -1,
                        cipherID: -1,
                      ),
                      changeDetector: () {
                        return localVer.hasUnsavedChanges;
                      },
                      showBottomNavBar: true,
                    );
                  } else {
                    nav.push(
                      () => ViewCipherScreen(
                        cipherID: null,
                        versionID: versionId,
                        versionType: VersionType.cloud,
                      ),
                      showBottomNavBar: true,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
