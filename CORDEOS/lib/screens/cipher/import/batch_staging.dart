import 'package:flutter/material.dart';

import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/version.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';

import 'package:cordeos/screens/cipher/edit_cipher.dart';

import 'package:cordeos/utils/date_utils.dart';

class BatchImportStaging extends StatelessWidget {
  final List<int> versionIDs;
  // On batch imports the versions are always saved prior to staging

  const BatchImportStaging({super.key, required this.versionIDs});

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
              itemCount: versionIDs.length,
              itemBuilder: (context, index) {
                final versionID = versionIDs[index];
                return Selector2<
                  LocalVersionProvider,
                  CipherProvider,
                  ({
                    int? cipherID,
                    String? title,
                    String? key,
                    int? bpm,
                    Duration? duration,
                  })
                >(
                  selector: (context, localVer, ciph) {
                    final version = localVer.getVersion(versionID);
                    final cipher = version != null
                        ? ciph.getCipher(version.cipherID)
                        : null;

                    return (
                      bpm: version?.bpm,
                      cipherID: version?.cipherID,
                      duration: version?.duration,
                      key: version?.transposedKey ?? cipher?.musicKey,
                      title: cipher?.title,
                    );
                  },
                  builder: (context, s, child) {
                    if (s.cipherID == null)
                      return const CircularProgressIndicator();
                    return GestureDetector(
                      onTap: () {
                        final ciph = context.read<CipherProvider>();
                        final localVer = context.read<LocalVersionProvider>();
                        final sect = context.read<SectionProvider>();

                        nav.push(
                          () => EditCipherScreen(
                            cipherID: s.cipherID!,
                            versionID: versionID,
                            versionType: VersionType.local,
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
                              Text(s.title!, style: textTheme.titleMedium),

                              // INFO
                              Row(
                                spacing: 8.0,
                                children: [
                                  Text(
                                    '${l10n.musicKey}: ${s.key!}',
                                    style: textTheme.bodyMedium,
                                  ),
                                  if (s.bpm != 0)
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.bpmWithPlaceholder(s.bpm.toString()),
                                      style: textTheme.bodyMedium,
                                    ),
                                  Text(
                                    l10n.durationWithPlaceholder(
                                      DateTimeUtils.formatDuration(s.duration!),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
