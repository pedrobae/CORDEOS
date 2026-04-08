import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/version/cloud_version_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';

import 'package:cordeos/widgets/common/filled_text_button.dart';

import 'package:flutter/material.dart';

class DownloadVersionSheet extends StatefulWidget {
  final String versionId;

  const DownloadVersionSheet({super.key, required this.versionId});

  @override
  State<DownloadVersionSheet> createState() => _DownloadVersionSheetState();
}

class _DownloadVersionSheetState extends State<DownloadVersionSheet> {
  final TextEditingController _versionNameController = TextEditingController();
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cloudVer = context.read<CloudVersionProvider>();
      final version = cloudVer.getVersion(widget.versionId);
      _versionNameController.text = version?.versionName ?? '';
    });
  }

  @override
  void dispose() {
    _versionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final sect = context.read<SectionProvider>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.downloadPlaceholder(AppLocalizations.of(context)!.cipher),
                  style: textTheme.titleMedium,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // FORM
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                LabeledTextField(
                  label: AppLocalizations.of(context)!.versionName,
                  controller: _versionNameController,
                ),
              ],
            ),

            // ACTIONS
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                // confirm
                FilledTextButton(
                  text: AppLocalizations.of(context)!.keepGoing,
                  isDark: true,
                  onPressed: () async {
                    Navigator.of(context).pop();
                    cloudVer.toggleIsDownloading(widget.versionId);

                    final cloudVersion = cloudVer.getVersion(widget.versionId);

                    if (cloudVersion == null) return;

                    // UPSERT CIPHER
                    final cipherID = await ciph.upsertCipher(
                      Cipher.fromVersionDto(cloudVersion),
                    );

                    // UPSERT VERSION
                    final versionID = await localVer.upsertVersion(
                      cloudVersion.toDomain(cipherId: cipherID),
                    );

                    cloudVer.removeVersion(widget.versionId);

                    sect.setNewSectionsInCache(
                      versionID,
                      cloudVersion.sections.map(
                        (code, section) => MapEntry(
                          code,
                          Section.fromFirestore(section, versionID),
                        ),
                      ),
                    );

                    await sect.createSections(versionID, originKey: versionID);

                    localVer.loadVersion(versionID);
                    ciph.loadCipher(cipherID);

                    cloudVer.toggleIsDownloading(widget.versionId);
                    // close sheet
                  },
                ),
                // cancel
                FilledTextButton(
                  text: AppLocalizations.of(context)!.cancel,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),

            SizedBox(),
          ],
        ),
      ),
    );
  }
}
