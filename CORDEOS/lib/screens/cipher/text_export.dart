import 'dart:async';
import 'dart:io';

import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/providers/playlist/playlist_provider.dart';
import 'package:cordeos/providers/transposition_provider.dart';
import 'package:flutter/material.dart';
import 'package:cordeos/helpers/song.dart';

import 'package:cordeos/l10n/app_localizations.dart';

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
  final int? versionID;
  final int? playlistID;

  TextExportScreen({super.key, this.versionID, this.playlistID}) {
    assert((versionID != null || playlistID != null));
  }

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
        Selector5<
          TranspositionProvider,
          PlaylistProvider,
          LocalVersionProvider,
          CipherProvider,
          SectionProvider,
          ({String chordPro, String songText, String fileName})
        >(
          selector: (context, trans, play, localVer, ciph, sect) {
            String fileName = '';
            final versionIDs = <int>[];
            if (widget.versionID != null) {
              versionIDs.add(widget.versionID!);
            }

            if (widget.playlistID != null) {
              final playlist = play.getPlaylist(widget.playlistID!);

              if (playlist == null) {
                throw Exception(
                  'Playlist not found for ID: ${widget.playlistID}',
                );
              }
              fileName = playlist.name;

              for (final item in playlist.items) {
                switch (item.type) {
                  case PlaylistItemType.version:
                    versionIDs.add(item.contentId!);
                    break;
                  case PlaylistItemType.flowItem:
                    //TODO-EXPORT FLOW ITEM
                    break;
                }
              }
            }

            final chordPros = <String>[];
            final holyricss = <String>[];

            for (final versionID in versionIDs) {
              final version = localVer.getVersion(versionID);
              if (version == null) {
                debugPrint('Version not found for ID: $versionID');
                continue;
              }
              final cipher = ciph.getCipher(version.cipherID);
              if (cipher == null) {
                debugPrint('Cipher not found for ID: $versionID');
                continue;
              }
              final sections = sect.getSections(versionID);
              final transposeChord = (String chord) => trans.transposeChord(
                chord,
                cipher.musicKey,
                version.transposedKey,
              );
              chordPros.add(
                SongHelper.convertToChordPro(cipher, version, sections),
              );
              holyricss.add(
                SongHelper.convertToRegularText(
                  cipher,
                  version,
                  sections,
                  transposeChord,
                ),
              );
            }

            final chordPro = chordPros.join('\f');
            final holyrics = holyricss.join('\f');

            return (chordPro: chordPro, songText: holyrics, fileName: fileName);
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
                      onPressed: _shareAsDoc(s.fileName),
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

  VoidCallback _shareAsDoc(String name) {
    return () async {
      final textToShare = _tabController.index == 0 ? _holyrics : _chordPro;
      final fileName = "${name}.txt";

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
