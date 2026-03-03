import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/models/domain/parsing_cipher.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/cipher/parser_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cordis/providers/cipher/import_provider.dart';
import 'package:provider/provider.dart';

class ImportTextScreen extends StatefulWidget {
  final int? cipherId;

  const ImportTextScreen({super.key, this.cipherId});

  @override
  State<ImportTextScreen> createState() => _ImportTextScreenState();
}

class _ImportTextScreenState extends State<ImportTextScreen> {
  final TextEditingController _importTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImportProvider>().setImportType(ImportType.text);
      context.read<ImportProvider>().setParsingStrategy(
        ParsingStrategy.doubleNewLine,
      );
    });
  }

  @override
  void dispose() {
    _importTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    return Consumer2<ImportProvider, ParserProvider>(
      builder: (context, imp, par, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.importFromText),
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
    return const Center(child: CircularProgressIndicator());
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
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
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
          style: textTheme.titleMedium,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.doubleNewLine,
              style: textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            Switch(
              inactiveTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.surface,
              trackOutlineColor: WidgetStatePropertyAll<Color>(
                colorScheme.primary,
              ),
              thumbIcon: WidgetStatePropertyAll<Icon>(
                Icon(Icons.circle),
              ),
              value: imp.parsingStrategy == ParsingStrategy.sectionLabels,
              onChanged: (value) {
                imp.setParsingStrategy(
                  value
                      ? ParsingStrategy.sectionLabels
                      : ParsingStrategy.doubleNewLine,
                );
              },
            ),
            Text(
              AppLocalizations.of(context)!.sectionLabels,
              style: textTheme.labelLarge,
              textAlign: TextAlign.center,
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
    final sect = Provider.of<SectionProvider>(context, listen: false);
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    final text = _importTextController.text;
    if (text.isNotEmpty) {
      await imp.importText(data: text);

      par.parseCipher(imp.importedCipher!);

      // Navigate to parsing screen
      nav.push(
        EditCipherScreen(
          versionType: VersionType.import,
          versionID: -1,
          cipherID: -1,
        ),
        changeDetector: () {
          return ciph.hasUnsavedChanges ||
              localVer.hasUnsavedChanges ||
              sect.hasUnsavedChanges;
        },
        showBottomNavBar: true,
      );
    }
  }
}
