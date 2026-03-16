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
    context.read<AutoScrollProvider>().currentItemIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      _setOriginalKey();
    });
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
      final version = localVer.getVersion(widget.versionID);
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
      LayoutSettingsProvider
    >(
      builder: (context, ciph, localVer, cloudVer, laySet, child) {
        final versionData = _extractVersionData(ciph, localVer, cloudVer);

        final filteredStructure = _filterStructure(
          versionData.songStructure,
          laySet,
        );

        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            _buildActionBar(laySet),
            _buildSectionsGrid(filteredStructure, versionData, laySet),
          ],
        );
      },
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
      final version = localVer.getVersion(widget.versionID);
      return _VersionData(
        title: cipher?.title ?? '',
        author: cipher?.author ?? '',
        bpm: version?.bpm ?? 0,
        duration: version?.duration ?? Duration.zero,
        songStructure: version?.songStructure ?? [],
      );
    }
  }

  List<String> _filterStructure(
    List<String> structure,
    LayoutSettingsProvider laySet,
  ) {
    final filteredStructure = <String>[];
    for (var sectionCode in structure) {
      if (!laySet.layoutFilters[LayoutFilter.annotations]! &&
          isAnnotation(sectionCode)) {
        continue;
      }
      if (!laySet.layoutFilters[LayoutFilter.transitions]! &&
          isTransition(sectionCode)) {
        continue;
      }
      filteredStructure.add(sectionCode);
    }
    return filteredStructure;
  }

  Widget _buildActionBar(LayoutSettingsProvider laySet) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Column(
      children: [
        Row(
          children: [
            if (isWideScreen)
              Expanded(child: StructureList(versionId: widget.versionID)),

            if (widget.versionType == VersionType.local) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _navigateToEditScreen(),
              ),
              SizedBox(width: 24),
            ],
            IconButton(
              icon: const Icon(Icons.format_paint),
              onPressed: _showStyleSettings(),
            ),
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: _showFilters(),
            ),
            SizedBox(width: 24),

            const Transposer(),
            SizedBox(width: 24),

            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  context.read<NavigationProvider>().attemptPop(context),
            ),
          ],
        ),
        if (!isWideScreen) StructureList(versionId: widget.versionID),
      ],
    );
  }

  Widget _buildSectionsGrid(
    List<String> filteredStructure,
    _VersionData versionData,
    LayoutSettingsProvider laySet,
  ) {
    return Consumer<SectionProvider>(
      builder: (context, sect, child) {
        if (sect.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sectionCardList = _buildSectionCards(
          filteredStructure,
          versionData,
          sect,
        );

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: laySet.scrollDirection,
              child: Wrap(
                direction: _getOppositeAxis(laySet.scrollDirection),
                spacing: 16,
                runSpacing: 16,
                children: sectionCardList,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSectionCards(
    List<String> filteredStructure,
    _VersionData versionData,
    SectionProvider sect,
  ) {
    final sectionCardList = <Widget>[_buildHeaderSection(versionData)];

    for (var (index, sectionCode) in filteredStructure.indexed) {
      final trimmedCode = sectionCode.trim();
      final scroll = context.read<AutoScrollProvider>();
      final section = sect.getSection(widget.versionID, trimmedCode);
      if (section == null || section.contentText.isEmpty) {
        continue;
      }

      final key = scroll.registerSection(0, index);
      scroll.setSectionLineCount(
        0,
        index,
        section.contentText.split('\n').length,
      );

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
            index: index,
            itemIndex: -1,
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

  Widget _buildHeaderSection(_VersionData versionData) {
    final textTheme = Theme.of(context).textTheme;
    final transpositionProvider = context.read<TranspositionProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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

  VoidCallback _navigateToEditScreen() {
    return () {
      final localVer = context.read<LocalVersionProvider>();
      final ciph = context.read<CipherProvider>();
      final sect = context.read<SectionProvider>();
      context.read<NavigationProvider>().push(
        () => EditCipherScreen(
          cipherID: widget.cipherID!,
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
    };
  }

  Axis _getOppositeAxis(Axis axis) {
    return axis == Axis.vertical ? Axis.horizontal : Axis.vertical;
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
