import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/providers/auto_scroll_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/providers/section_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/utils/date_utils.dart';
import 'package:cordis/utils/section_constants.dart';
import 'package:cordis/widgets/ciphers/transposer.dart';
import 'package:cordis/widgets/ciphers/viewer/annotation_card.dart';
import 'package:cordis/widgets/ciphers/viewer/section_card.dart';
import 'package:cordis/widgets/ciphers/viewer/structure_list.dart';
import 'package:cordis/widgets/settings/content_filters.dart';
import 'package:cordis/widgets/settings/style_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:cordis/providers/cipher/cipher_provider.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/version/cloud_version_provider.dart';
import 'package:cordis/providers/version/local_version_provider.dart';
import 'package:cordis/screens/cipher/edit_cipher.dart';

class ViewCipherScreen extends StatefulWidget {
  final int? cipherID;
  final dynamic versionID;
  final VersionType versionType;

  const ViewCipherScreen({
    super.key,
    required this.cipherID,
    this.versionID,
    required this.versionType,
  });

  @override
  State<ViewCipherScreen> createState() => _ViewCipherScreenState();
}

class _ViewCipherScreenState extends State<ViewCipherScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      _setOriginalKey();
    });
  }

  void _setOriginalKey() {
    final trans = context.read<TranspositionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();
    final localVer = context.read<LocalVersionProvider>();
    final ciph = context.read<CipherProvider>();

    final String originalKey;
    final String? transposedKey;

    if (widget.versionType == VersionType.cloud) {
      final version = cloudVer.getVersion(widget.versionID)!;
      originalKey = version.originalKey;
      transposedKey = version.transposedKey;
    } else {
      final cipher = ciph.getCipher(widget.cipherID!);
      final version = localVer.cachedVersion(widget.versionID);
      originalKey = cipher!.musicKey;
      transposedKey = version?.transposedKey;
    }
    trans.setOriginalKey(originalKey);
    trans.setTransposedKey(transposedKey);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      CipherProvider,
      LocalVersionProvider,
      CloudVersionProvider,
      SectionProvider
    >(
      builder: (context, ciph, localVer, cloudVer, sect, child) {
        if (_isLoading(ciph, localVer, cloudVer, sect)) {
          return _buildLoadingState();
        }

        if (_hasError(ciph, localVer, cloudVer, sect)) {
          return _buildErrorState(ciph, localVer, cloudVer, sect);
        }

        return _buildContentState(ciph, localVer, cloudVer, sect);
      },
    );
  }

  bool _isLoading(
    CipherProvider ciph,
    LocalVersionProvider localVer,
    CloudVersionProvider cloudVer,
    SectionProvider sect,
  ) {
    return ciph.isLoading ||
        localVer.isLoading ||
        cloudVer.isLoading ||
        sect.isLoading;
  }

  bool _hasError(
    CipherProvider ciph,
    LocalVersionProvider localVer,
    CloudVersionProvider cloudVer,
    SectionProvider sect,
  ) {
    return ciph.error != null ||
        localVer.error != null ||
        cloudVer.error != null ||
        sect.error != null;
  }

  Scaffold _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Carregando...')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _buildErrorState(
    CipherProvider ciph,
    LocalVersionProvider localVer,
    CloudVersionProvider cloudVer,
    SectionProvider sect,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final errorMessage =
        ciph.error ?? localVer.error ?? cloudVer.error ?? sect.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Erro: $errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState(
    CipherProvider cipherProvider,
    LocalVersionProvider localVersionProvider,
    CloudVersionProvider cloudVersionProvider,
    SectionProvider sectionProvider,
  ) {
    final versionData = _extractVersionData(
      cipherProvider,
      localVersionProvider,
      cloudVersionProvider,
    );
    final filteredStructure = _filterSongStructure(versionData.songStructure);
    final sectionCardList = _buildSectionCards(
      sectionProvider,
      filteredStructure,
    );

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        _buildActionBar(cipherProvider, localVersionProvider, sectionProvider),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                spacing: 16,
                children: [
                  _buildHeaderSection(versionData),
                  _buildSongStructureSection(filteredStructure),
                  _buildSectionsGrid(sectionCardList),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _VersionData _extractVersionData(
    CipherProvider ciph,
    LocalVersionProvider localVer,
    CloudVersionProvider cloudVer,
  ) {
    if (widget.versionID is String) {
      final versionDto = cloudVer.getVersion(widget.versionID)!;
      return _VersionData(
        title: versionDto.title,
        author: versionDto.author,
        bpm: versionDto.bpm,
        duration: Duration(seconds: versionDto.duration),
        songStructure: versionDto.songStructure,
      );
    } else {
      final cipher = ciph.getCipher(widget.cipherID!);
      final version = localVer.cachedVersion(widget.versionID);
      return _VersionData(
        title: cipher?.title ?? '',
        author: cipher?.author ?? '',
        bpm: version?.bpm ?? 0,
        duration: version?.duration ?? Duration.zero,
        songStructure: version?.songStructure ?? [],
      );
    }
  }

  List<String> _filterSongStructure(List<String> songStructure) {
    final laySet = context.read<LayoutSettingsProvider>();
    final filtered = <String>[];
    for (var sectionCode in songStructure) {
      if (!laySet.showAnnotations && isAnnotation(sectionCode)) continue;
      if (!laySet.showTransitions && isTransition(sectionCode)) continue;
      filtered.add(sectionCode);
    }
    return filtered;
  }

  List<Widget> _buildSectionCards(
    SectionProvider sect,
    List<String> filteredStructure,
  ) {
    final scrollProvider = context.read<AutoScrollProvider>();
    final sectionCardList = <Widget>[];

    for (var (index, sectionCode) in filteredStructure.indexed) {
      final trimmedCode = sectionCode.trim();
      final section = sect.getSection(widget.versionID, trimmedCode);

      if (section == null || section.contentText.isEmpty) continue;

      if (scrollProvider.sectionKeys[index] == null) {
        scrollProvider.sectionKeys[index] = GlobalKey();
      }
      final key = scrollProvider.sectionKeys[index]!;

      if (isAnnotation(trimmedCode)) {
        sectionCardList.add(
          AnnotationCard(
            key: key,
            sectionText: section.contentText,
            sectionType: section.contentType,
          ),
        );
      } else {
        sectionCardList.add(
          SectionCard(
            key: key,
            sectionType: section.contentType,
            sectionCode: trimmedCode,
            sectionText: section.contentText,
            sectionColor: section.contentColor,
          ),
        );
      }
    }

    sectionCardList.add(const SizedBox(height: 200));
    return sectionCardList;
  }

  Widget _buildActionBar(
    CipherProvider ciph,
    LocalVersionProvider localVer,
    SectionProvider sect,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          if (widget.versionType == VersionType.local)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditScreen(ciph, localVer, sect),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showStyleSettings(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilters(),
          ),
          const Spacer(),
          const Transposer(),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                context.read<NavigationProvider>().attemptPop(context),
          ),
        ],
      ),
    );
  }

  void _navigateToEditScreen(
    CipherProvider ciph,
    LocalVersionProvider localVer,
    SectionProvider sect,
  ) {
    context.read<NavigationProvider>().push(
      EditCipherScreen(
        cipherID: widget.cipherID,
        versionID: widget.versionID,
        versionType: widget.versionType,
      ),
      changeDetector: () {
        return widget.versionID is String
            ? false
            : (localVer.hasUnsavedChanges ||
                  ciph.hasUnsavedChanges ||
                  sect.hasUnsavedChanges);
      },
      showBottomNavBar: true,
    );
  }

  Widget _buildHeaderSection(_VersionData versionData) {
    final textTheme = Theme.of(context).textTheme;
    final transpositionProvider = context.read<TranspositionProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(versionData.title, style: textTheme.titleMedium),
        Text(
          '${AppLocalizations.of(context)!.by} ${versionData.author}',
          style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8.0),
        _buildMetadataRow(versionData, transpositionProvider, textTheme),
      ],
    );
  }

  Widget _buildMetadataRow(
    _VersionData versionData,
    TranspositionProvider trans,
    TextTheme textTheme,
  ) {
    return Row(
      spacing: 16.0,
      children: [
        Text(
          AppLocalizations.of(
            context,
          )!.keyWithPlaceholder(trans.transposedKey ?? trans.originalKey),
          style: textTheme.bodySmall,
        ),
        if (versionData.bpm != 0)
          Text(
            AppLocalizations.of(
              context,
            )!.bpmWithPlaceholder(versionData.bpm.toString()),
            style: textTheme.bodySmall,
          )
        else
          Text('-', style: textTheme.bodySmall),
        if (versionData.duration != Duration.zero)
          Text(
            AppLocalizations.of(context)!.durationWithPlaceholder(
              DateTimeUtils.formatDuration(versionData.duration),
            ),
            style: textTheme.bodySmall,
          )
        else
          Text('-', style: textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSongStructureSection(List<String> filteredStructure) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.songStructure,
          style: textTheme.titleMedium,
        ),
        StructureList(
          versionId: widget.versionID,
          filteredStructure: filteredStructure,
          scrollController: scrollController,
        ),
      ],
    );
  }

  Widget _buildSectionsGrid(List<Widget> sectionCardList) {
    final laySet = context.read<LayoutSettingsProvider>();

    return MasonryGridView.count(
      crossAxisCount: laySet.columnCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: sectionCardList.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) => sectionCardList[index],
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final sect = context.read<SectionProvider>();
    final cloudVer = context.read<CloudVersionProvider>();

    switch (widget.versionType) {
      case VersionType.import:
      case VersionType.brandNew:
        break;
      case VersionType.local:
      case VersionType.playlist:
        if (widget.versionID != null) {
          await sect.loadSectionsOfVersion(widget.versionID);
        }
        break;
      case VersionType.cloud:
        if (widget.versionID != null) {
          final version = cloudVer.getVersion(widget.versionID);
          sect.setNewSectionsInCache(
            widget.versionID,
            version!.toDomain().sections!,
          );
        }
        break;
    }
  }

  VoidCallback _showStyleSettings() {
    return () {
      showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        context: context,
        isScrollControlled: true,
        builder: (context) => BottomSheet(
          onClosing: () {},
          builder: (context) => const StyleSettings(),
        ),
      );
    };
  }

  VoidCallback _showFilters() {
    return () {
      showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        context: context,
        isScrollControlled: true,
        builder: (context) => BottomSheet(
          onClosing: () {},
          builder: (context) => const ContentFilters(),
        ),
      );
    };
  }
}

class _VersionData {
  final String title;
  final String author;
  final int bpm;
  final Duration duration;
  final List<String> songStructure;

  _VersionData({
    required this.title,
    required this.author,
    required this.bpm,
    required this.duration,
    required this.songStructure,
  });
}
