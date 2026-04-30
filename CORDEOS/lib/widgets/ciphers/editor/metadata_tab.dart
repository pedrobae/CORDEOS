import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:cordeos/widgets/ciphers/editor/metadata.dart/add_tag_sheet.dart';
import 'package:cordeos/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:cordeos/widgets/common/labeled_duration_picker.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:cordeos/widgets/common/labeled_language_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum InfoField {
  title,
  author,
  versionName,
  key,
  bpm,
  duration,
  language,
  tags,
  link,
}

class MetadataTab extends StatefulWidget {
  final int cipherID;
  final int versionID;
  final VersionType versionType;
  final bool isEnabled;

  const MetadataTab({
    super.key,
    required this.cipherID,
    required this.versionID,
    required this.versionType,
    this.isEnabled = true,
  });

  @override
  State<MetadataTab> createState() => _MetadataTabState();
}

class _MetadataTabState extends State<MetadataTab> {
  Map<InfoField, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    _createControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProviderData();
      _addListeners();
    });
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _createControllers() {
    for (var i = 0; i < InfoField.values.length; i++) {
      switch (InfoField.values[i]) {
        case InfoField.key:
        case InfoField.tags:
        case InfoField.language:
          // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
          break;
        default:
          controllers[InfoField.values[i]] = TextEditingController();
      }
    }
  }

  void _syncWithProviderData() {
    if (mounted) {
      final localVer = context.read<LocalVersionProvider>();
      final ciph = context.read<CipherProvider>();

      switch (widget.versionType) {
        case VersionType.cloud:
          throw Exception("Cannot edit Cloud version");
        case VersionType.local:
        case VersionType.playlist:
        case VersionType.import:
          final cipher = ciph.getCipher(widget.cipherID)!;
          final version = localVer.getVersion(widget.versionID)!;
          controllers[InfoField.title]!.text = cipher.title;
          controllers[InfoField.author]!.text = cipher.author;
          controllers[InfoField.versionName]!.text = version.versionName;
          controllers[InfoField.bpm]!.text = version.bpm.toString();
          controllers[InfoField.duration]!.text = DateTimeUtils.formatDuration(
            version.duration,
          );
          controllers[InfoField.link]!.text = (cipher.links).join(',');
          break;
        case VersionType.brandNew:
          // Empty controllers for brand new versions
          break;
      }
    }
  }

  void _addListeners() {
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();

    for (var entry in controllers.entries) {
      final field = entry.key;
      final controller = entry.value;
      switch (field) {
        case InfoField.title:
          controller.addListener(
            () => ciph.cacheUpdates(widget.cipherID, title: controller.text),
          );
          break;
        case InfoField.author:
          controller.addListener(
            () => ciph.cacheUpdates(widget.cipherID, author: controller.text),
          );
          break;
        case InfoField.versionName:
          controller.addListener(
            () => localVer.cacheUpdates(
              widget.versionID,
              versionName: controller.text,
            ),
          );
          break;
        case InfoField.bpm:
          controller.addListener(() {
            final bpm = int.tryParse(controller.text) ?? 0;
            localVer.cacheUpdates(widget.versionID, bpm: bpm);
          });
          break;
        case InfoField.duration:
          controller.addListener(() {
            final duration = DateTimeUtils.parseDuration(controller.text);
            localVer.cacheUpdates(widget.versionID, duration: duration);
          });
          break;
        case InfoField.link:
          controller.addListener(
            () => ciph.cacheUpdates(widget.cipherID, links: controller.text.split(',')),
          );
        case InfoField.language:
        case InfoField.tags:
        case InfoField.key:
          // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
          break;
      }
    }
  }

  TextEditingController _getController(InfoField field) {
    return controllers[field]!;
  }

  String _getLabel(InfoField field) {
    final l10n = AppLocalizations.of(context)!;
    return switch (field) {
      InfoField.title => l10n.title,
      InfoField.author => l10n.author,
      InfoField.versionName => l10n.versionName,
      InfoField.bpm => l10n.bpm,
      InfoField.duration => l10n.duration,
      InfoField.key => l10n.musicKey,
      InfoField.language => l10n.language,
      InfoField.tags => l10n.pluralPlaceholder(l10n.tag),
      InfoField.link => l10n.link,
    };
  }

  String _getHint(InfoField field) {
    final l10n = AppLocalizations.of(context)!;
    return switch (field) {
      InfoField.title => l10n.titleHint,
      InfoField.author => l10n.authorHint,
      InfoField.versionName => l10n.versionNameHint,
      InfoField.bpm => l10n.bpmHint,
      InfoField.duration => l10n.durationHint,
      InfoField.key => l10n.keyHint,
      InfoField.language => l10n.languageHint,
      InfoField.tags => l10n.tagHint,
      InfoField.link => l10n.linkHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16.0,
      children: [
        for (var field in InfoField.values)
          switch (field) {
            InfoField.key => _buildKeySelector(),
            InfoField.language => _buildLanguagePicker(),
            InfoField.tags => _buildTags(),
            InfoField.duration => DurationPickerField(
              controller: _getController(field),
              label: _getLabel(field),
            ),
            InfoField.bpm => LabeledTextField(
              label: _getLabel(field),
              hint: _getHint(field),
              controller: _getController(field),
              isEnabled: widget.isEnabled,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }
                final bpm = int.tryParse(value);
                if (bpm == null || bpm <= 0) {
                  return AppLocalizations.of(context)!.intValidationError;
                }
                return null;
              },
            ),
            _ => LabeledTextField(
              label: _getLabel(field),
              hint: _getHint(field),
              controller: _getController(field),
              isEnabled: widget.isEnabled,
            ),
          },
      ],
    );
  }

  Widget _buildKeySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(l10n.musicKey, style: theme.textTheme.labelMedium),
        Selector<CipherProvider, String?>(
          selector: (context, ciph) {
            final cipher = ciph.getCipher(widget.cipherID);
            return cipher?.musicKey;
          },
          builder: (context, originalKey, child) {
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SelectKeySheet(
                      initialKey: originalKey ?? '',
                      originalKey: originalKey ?? '',
                      versionID: widget.versionID,
                      showOriginal: false,
                      onKeySelected: (key) {
                        context.read<CipherProvider>().cacheMusicKey(
                          widget.cipherID,
                          key,
                        );
                      },
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.shadow, width: 1),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      originalKey ?? l10n.keyHint,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguagePicker() {
    return Selector<CipherProvider, String>(
      selector: (context, ciph) {
        final cipher = ciph.getCipher(widget.cipherID);
        return cipher?.language ?? '';
      },
      builder: (context, language, child) {
        return LabeledLanguagePicker(
          language: language,
          onLanguageChanged: (value) {
            context.read<CipherProvider>().cacheUpdates(
              widget.cipherID,
              language: value,
            );
          },
        );
      },
    );
  }

  Widget _buildTags() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<CipherProvider>(
      builder: (context, ciph, child) {
        final tags = ciph.getCipher(widget.cipherID)?.tags ?? [];

        return Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.pluralPlaceholder(l10n.tag),
              style: textTheme.labelMedium,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var tag in tags)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      spacing: 4,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            ciph.cacheRemoveTag(widget.cipherID, tag);
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(tag, style: textTheme.labelMedium),
                      ],
                    ),
                  ),
              ],
            ),
            FilledTextButton(
              text: l10n.addPlaceholder(l10n.tag),
              icon: Icons.add,
              isDense: true,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return AddTagSheet(
                    cipherID: widget.cipherID,
                    versionID: widget.versionID,
                    versionType: widget.versionType,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
