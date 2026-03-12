import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/cipher.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/add_tag_sheet.dart';
import 'package:cordis/widgets/ciphers/editor/metadata.dart/select_key_sheet.dart';
import 'package:cordis/widgets/common/labeled_duration_picker.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:cordis/widgets/common/labeled_language_picker.dart';
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
    for (var i = 0; i < InfoField.values.length; i++) {
      switch (InfoField.values[i]) {
        case InfoField.key:
        case InfoField.tags:
          // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
          break;
        default:
          controllers[InfoField.values[i]] = TextEditingController();
      }
    }
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
          _syncLocalVersion(cipher, version);
          break;
        case VersionType.brandNew:
          // Empty controllers for brand new versions
          break;
      }
    }
  }

  void _syncLocalVersion(Cipher cipher, Version version) {
    controllers[InfoField.title]!.text = cipher.title;
    controllers[InfoField.author]!.text = cipher.author;
    controllers[InfoField.versionName]!.text = version.versionName;
    controllers[InfoField.bpm]!.text = version.bpm.toString();
    controllers[InfoField.language]!.text = cipher.language;
    controllers[InfoField.duration]!.text = DateTimeUtils.formatDuration(
      version.duration,
    );
    // KEY FIELD IS HANDLED BY TRANSPOSITION PROVIDER
    // TAGS CONTROLLER IS NOT USED, ADDING TAGS IS HANDLED BY A BOTTOM SHEET
  }

  void _addListeners() {
    final ciph = context.read<CipherProvider>();
    final localVer = context.read<LocalVersionProvider>();

    for (var field in InfoField.values) {
      switch (field) {
        case InfoField.key:
        case InfoField.tags:
          // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
          break;
        default:
          controllers[field]!.addListener(() {
            final text = controllers[field]!.text;
            switch (field) {
              case InfoField.title:
                ciph.cacheUpdates(widget.cipherID, title: text);
                break;

              case InfoField.author:
                ciph.cacheUpdates(widget.cipherID, author: text);
                break;
              case InfoField.versionName:
                localVer.cacheUpdates(widget.versionID, versionName: text);
                break;
              case InfoField.language:
                ciph.cacheUpdates(widget.cipherID, language: text);
                break;
              case InfoField.bpm:
                final bpm = int.tryParse(text) ?? 0;
                localVer.cacheUpdates(widget.versionID, bpm: bpm);
                break;
              case InfoField.duration:
                final duration = DateTimeUtils.parseDuration(text);
                localVer.cacheUpdates(widget.versionID, duration: duration);
                break;
              case InfoField.tags:
              case InfoField.key:
                // THESE FIELDS ARE HANDLED SEPARATELY, NOT USING TEXT CONTROLLERS
                break;
            }
          });
      }
    }
  }

  TextEditingController _getController(InfoField field) {
    return controllers[field]!;
  }

  String _getLabel(InfoField field) {
    return switch (field) {
      InfoField.title => AppLocalizations.of(context)!.title,
      InfoField.author => AppLocalizations.of(context)!.author,
      InfoField.versionName => AppLocalizations.of(context)!.versionName,
      InfoField.bpm => AppLocalizations.of(context)!.bpm,
      InfoField.duration => AppLocalizations.of(context)!.duration,
      InfoField.key => AppLocalizations.of(context)!.musicKey,
      InfoField.language => AppLocalizations.of(context)!.language,
      InfoField.tags => AppLocalizations.of(
        context,
      )!.pluralPlaceholder(AppLocalizations.of(context)!.tag),
    };
  }

  String _getHint(InfoField field) {
    return switch (field) {
      InfoField.title => AppLocalizations.of(context)!.titleHint,
      InfoField.author => AppLocalizations.of(context)!.authorHint,
      InfoField.versionName => AppLocalizations.of(context)!.versionNameHint,
      InfoField.bpm => AppLocalizations.of(context)!.bpmHint,
      InfoField.duration => AppLocalizations.of(context)!.durationHint,
      InfoField.key => AppLocalizations.of(context)!.keyHint,
      InfoField.language => AppLocalizations.of(context)!.languageHint,
      InfoField.tags => AppLocalizations.of(context)!.tagHint,
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
                InfoField.duration => DurationPickerField(
                  controller: _getController(field),
                  label: _getLabel(field),
                ),
                InfoField.tags => _buildTags(
                  context: context,
                  field: field,
                ),
                InfoField.bpm => LabeledTextField(
                  label: _getLabel(field),
                  hint: _getHint(field),
                  controller: _getController(field),
                  isEnabled: widget.isEnabled,
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
                InfoField.key => _buildKeySelector(
                  context: context,
                  field: field,
                ),
                InfoField.language => LabeledLanguagePicker(
                  language: _getController(field).text,
                  onLanguageChanged: (value) {
                    _getController(field).text = value;
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

  Widget _buildKeySelector({
    required BuildContext context,
    required InfoField field,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(_getLabel(field), style: theme.textTheme.labelLarge),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return SelectKeySheet();
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.shadow, width: 1),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<TranspositionProvider>(
                  builder: (context, tp, child) {
                    return Text(
                      tp.transposedKey ?? AppLocalizations.of(context)!.keyHint,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags({
    required BuildContext context,
    required InfoField field,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;


    return Consumer<CipherProvider>(
      builder: (context, ciph, child) {
    final tags = ciph.getCipher(widget.cipherID)?.tags ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_getLabel(field), style: textTheme.labelLarge),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (var tag in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: textTheme.labelMedium),
                  ),
              ],
            ),
            FilledTextButton(
              text: AppLocalizations.of(
                context,
              )!.addPlaceholder(AppLocalizations.of(context)!.tag),
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
      }
    );
  }
}
