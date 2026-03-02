import 'package:cordis/l10n/app_localizations.dart';

import 'package:cordis/models/domain/cipher/cipher.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';

import 'package:cordis/widgets/common/filled_text_button.dart';

import 'package:flutter/material.dart';

class DownloadVersionSheet extends StatefulWidget {
  final String versionId;

  const DownloadVersionSheet({super.key, required this.versionId});

  @override
  State<DownloadVersionSheet> createState() => _DownloadVersionSheetState();
}

class _DownloadVersionSheetState extends State<DownloadVersionSheet> {
  final TextEditingController versionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cloudVersionProvider = context.read<CloudVersionProvider>();

      final version = cloudVersionProvider.getVersion(widget.versionId);

      versionNameController.text = version?.versionName ?? '';
    });
  }

  @override
  void dispose() {
    versionNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer3<
      CipherProvider,
      LocalVersionProvider,
      CloudVersionProvider
    >(
      builder:
          (
            context,
            cipherProvider,
            localVersionProvider,
            cloudVersionProvider,
            child,
          ) {
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
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.downloadPlaceholder(
                            AppLocalizations.of(context)!.cipher,
                          ),
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
                        Text(
                          AppLocalizations.of(context)!.versionName,
                          style: textTheme.labelLarge,
                        ),
                        TextField(
                          controller: versionNameController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.versionNameHint,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: BorderSide(
                                color: colorScheme.surfaceContainerLowest,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                              borderSide: BorderSide(
                                color: colorScheme.surfaceContainerLowest,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // ACTIONS
                    // confirm
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.keepGoing,
                      isDark: true,
                      onPressed: () async {
                        final cloudVersion = cloudVersionProvider.getVersion(
                          widget.versionId,
                        );

                        if (cloudVersion == null) return;

                        // UPSERT CIPHER
                        final cipherId = await cipherProvider.upsertCipher(
                          Cipher.fromVersionDto(cloudVersion),
                        );

                        // UPSERT VERSION
                        await localVersionProvider.upsertVersion(
                          cloudVersion.toDomain(cipherId: cipherId),
                        );

                        // close sheet
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(height: 16),
                    // cancel
                    FilledTextButton(
                      text: AppLocalizations.of(context)!.cancel,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),

                    SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
    );
  }
}
