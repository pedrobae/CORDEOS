import 'package:flutter/material.dart';

import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/models/dtos/version_dto.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';

import 'package:cordeos/screens/cipher/edit_cipher.dart';

import 'package:cordeos/utils/date_utils.dart';

class BatchImportStaging extends StatelessWidget {
  final List<VersionDto> songs;

  const BatchImportStaging({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final nav = context.read<NavigationProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 25,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned(
                  left: 0,
                  child: GestureDetector(
                    onTap: () => nav.pop(),
                    child: SizedBox(
                      width: 25,
                      height: 25,
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Text(
                    l10n.batchImport,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final dto = songs[index];
                return GestureDetector(
                  onTap: () {
                    final ciph = context.read<CipherProvider>();
                    final localVer = context.read<LocalVersionProvider>();
                    final sect = context.read<SectionProvider>();

                    nav.push(
                      () => EditCipherScreen(
                        cipherID: -1,
                        versionID: -1,
                        versionDto: dto,
                        versionType: VersionType.import,
                      ),
                      showBottomNavBar: true,
                      changeDetector: () =>
                          ciph.hasUnsavedChanges ||
                          localVer.hasUnsavedChanges ||
                          sect.hasUnsavedChanges,
                      onChangeDiscarded: () {
                        localVer.clearVersionFromCache();
                        ciph.clearCipherFromCache();
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.surfaceContainerLowest,
                      ),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Container(
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
                          Text(dto.title, style: textTheme.titleMedium),

                          // INFO
                          Row(
                            spacing: 8.0,
                            children: [
                              Text(
                                '${l10n.musicKey}: ${dto.transposedKey ?? dto.originalKey}',
                                style: textTheme.bodyMedium,
                              ),
                              if (dto.bpm != 0)
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.bpmWithPlaceholder(dto.bpm.toString()),
                                  style: textTheme.bodyMedium,
                                ),
                              Text(
                                l10n.durationWithPlaceholder(
                                  DateTimeUtils.formatDuration(
                                    Duration(seconds: dto.duration),
                                  ),
                                ),
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
