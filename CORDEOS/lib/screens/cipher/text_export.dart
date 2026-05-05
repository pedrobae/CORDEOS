import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cordeos/helpers/song.dart';

import 'package:cordeos/l10n/app_localizations.dart';

import 'package:cordeos/models/domain/cipher/cipher.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/cipher/cipher_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';
import 'package:cordeos/providers/section/section_provider.dart';
import 'package:cordeos/providers/version/local_version_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TextExportScreen extends StatefulWidget {
  final int versionID;

  const TextExportScreen({super.key, required this.versionID});

  @override
  State<TextExportScreen> createState() => _TextExportScreenState();
}

class _TextExportScreenState extends State<TextExportScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  bool copied = false;
  String _chordPro = '';
  String _holyrics = '';
  Timer? _resetCopiedTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _resetCopiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final nav = context.read<NavigationProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        // HEADER
        AppBar(
          title: Text(l10n.export, style: textTheme.titleMedium),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: colorScheme.onSurface,
              size: 30,
            ),
            onPressed: () => nav.pop(),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Holyrics'),
            Tab(text: 'ChordPro'),
          ],
        ),
        Selector3<
          LocalVersionProvider,
          CipherProvider,
          SectionProvider,
          ({String chordPro, String songText, Cipher cipher})
        >(
          selector: (context, localVer, ciph, sect) {
            final version = localVer.getVersion(widget.versionID);
            if (version == null) {
              throw Exception('Couldnt find version ${widget.versionID}');
            }
            final cipher = ciph.getCipher(version.cipherID);
            if (cipher == null) {
              throw Exception('Couldnt find cipher ${version.cipherID}');
            }
            final sections = sect.getSections(widget.versionID);

            final chordPro = SongHelper.convertToChordPro(
              cipher,
              version,
              sections,
            );

            final holyrics = SongHelper.convertToRegularText(
              cipher,
              version,
              sections,
            );

            _chordPro = chordPro;
            _holyrics = holyrics;

            return (chordPro: chordPro, songText: holyrics, cipher: cipher);
          },
          builder: (context, s, child) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // TEXT TAB
                          SelectableText(s.songText),

                          // CHORDPRO TAB
                          SelectableText(s.chordPro),
                        ],
                      ),
                    ),
                    FilledTextButton(
                      text: copied ? l10n.copied : l10n.copy,
                      icon: copied ? Icons.check : Icons.copy,
                      isDark: true,
                      onPressed: () {
                        copied ? () {} : _copy();
                      },
                    ),
                    FilledTextButton(
                      text: l10n.share,
                      icon: Icons.edit_document,
                      onPressed: _shareAsDoc(s.cipher),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _copy() async {
    final textToCopy = _tabController.index == 0 ? _holyrics : _chordPro;

    await Clipboard.setData(ClipboardData(text: textToCopy));

    if (!mounted) return;

    setState(() {
      copied = true;
    });

    // Auto-reset after 2 seconds
    _resetCopiedTimer?.cancel();
    _resetCopiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          copied = false;
        });
      }
    });
  }

  VoidCallback _shareAsDoc(Cipher cipher) {
    return () async {
      final textToShare = _tabController.index == 0 ? _holyrics : _chordPro;
      final fileName = "${cipher.title}.txt";

      try {
        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/$fileName";
        final file = File(filePath);

        await file.writeAsString(textToShare);

        await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
      } catch (e) {
        debugPrint(e.toString());
      }
    };
  }
}
