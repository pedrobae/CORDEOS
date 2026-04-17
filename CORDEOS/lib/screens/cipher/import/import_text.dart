import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/cipher/parser_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/screens/cipher/edit_cipher.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/icon_load_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/providers/cipher/import_provider.dart';
import 'package:provider/provider.dart';

class ImportTextScreen extends StatefulWidget {
  final int cipherID;
  final int versionID;

  const ImportTextScreen({super.key, this.cipherID = -1, this.versionID = -1});

  @override
  State<ImportTextScreen> createState() => _ImportTextScreenState();
}

class _ImportTextScreenState extends State<ImportTextScreen> {
  final TextEditingController _importTextController = TextEditingController();

  void _onImportTextChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _importTextController.addListener(_onImportTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImportProvider>().setImportType(ImportType.text);
      context.read<ImportProvider>().setParsingStrategy(
        ParsingStrategy.doubleNewLine,
      );
    });
  }

  @override
  void dispose() {
    _importTextController.removeListener(_onImportTextChanged);
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    final textTheme = Theme.of(context).textTheme;

    return Consumer2<ImportProvider, ParserProvider>(
      builder: (context, imp, par, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.importFromText,
              style: textTheme.titleMedium,
            ),
            leading: BackButton(onPressed: () => nav.attemptPop(context)),
          ),
          body: imp.error != null
              ? _buildErrorState(imp)
              : imp.isImporting
              ? _buildLoadingState()
              : _buildContentState(imp, par),
        );
      },
    );
  }

  Widget _buildErrorState(ImportProvider imp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.errorMessage(
              AppLocalizations.of(context)!.importFromText,
              imp.error!,
            ),
            style: const TextStyle(color: Colors.red),
          ),
          FilledButton.icon(
            label: Text(AppLocalizations.of(context)!.tryAgain),
            onPressed: () => imp.clearError(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: IconLoadIndicator(size: 150));
  }

  Widget _buildContentState(ImportProvider imp, ParserProvider par) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 16.0,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextInputField(),
            _buildParsingStrategySection(imp),
            _buildImportButton(imp, par),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputField() {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: TextField(
        expands: true,
        maxLines: null,
        selectAllOnFocus: true,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        textAlignVertical: TextAlignVertical(y: -1),
        controller: _importTextController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.pasteTextPrompt,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildParsingStrategySection(ImportProvider imp) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.parsingStrategy,
          style: textTheme.labelLarge,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.doubleNewLine,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.left,
              ),
            ),
            Switch(
              inactiveTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.surface,
              trackOutlineColor: WidgetStatePropertyAll<Color>(
                colorScheme.primary,
              ),
              thumbIcon: WidgetStatePropertyAll<Icon>(Icon(Icons.circle)),
              value: imp.parsingStrategy == ParsingStrategy.sectionLabels,
              onChanged: (value) {
                imp.toggleParsingStrategy();
              },
            ),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.sectionLabels,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportButton(ImportProvider imp, ParserProvider par) {
    return FilledTextButton(
      text: AppLocalizations.of(context)!.import,
      isDark: true,
      isDisabled: _importTextController.text.isEmpty,
      onPressed: () => _parse(context, imp, par),
    );
  }

  Future<void> _parse(
    BuildContext context,
    ImportProvider imp,
    ParserProvider par,
  ) async {
    final localVer = Provider.of<LocalVersionProvider>(context, listen: false);
    final ciph = Provider.of<CipherProvider>(context, listen: false);
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    final text = _importTextController.text;
    if (text.isNotEmpty) {
      final importedCipher = await imp.importText(data: text);

      if (importedCipher == null) {
        throw Exception('Failed to import text');
      }
      par.parseCipher(importedCipher);

      if (widget.cipherID != -1 && widget.versionID != -1) {
        // CLEAN THE SCREEN STACK IF COMING FROM EDITING
        nav.pop(); // pop the import screen
        nav.pop(); // pop the edit cipher screen - bypass change detection, since we're reopening it with the new data right after
      }

      // Navigate to edit cipher screen
      nav.push(
        () => EditCipherScreen(
          versionType: VersionType.import,
          versionID: widget.versionID,
          cipherID: widget.cipherID,
        ),
        keepAlive: true,
        changeDetector: () {
          return ciph.hasUnsavedChanges || localVer.hasUnsavedChanges;
        },
        onChangeDiscarded: () async {
          await localVer.loadVersion(widget.versionID);
          await ciph.loadCipher(widget.cipherID);
        },
      );
    }
  }
}
