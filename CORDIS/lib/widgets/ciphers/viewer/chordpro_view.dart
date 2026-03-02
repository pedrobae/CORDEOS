import 'package:cordis/models/ui/song.dart';
import 'package:cordis/providers/layout_settings_provider.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'line_view.dart';

class ChordProView extends StatelessWidget {
  final String? chordPro;
  final bool isAnnotation;

  const ChordProView({super.key, this.chordPro, this.isAnnotation = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer2<LayoutSettingsProvider, TranspositionProvider>(
      builder: (context, ls, tp, child) {
        final parsedSong = Song.fromChordPro(chordPro);

        List<Widget> sectionChildren = [];

        // CHECKS FILTERS - chords and lyrics
        if (ls.showChords && (ls.showLyrics || isAnnotation)) {
          /// ITERATE THROUGH LYRIC LINES
          for (int i = 0; i < parsedSong.linesMap.length; i++) {
            /// EMPTY LINES WITH CHORDS ONLY
            if (parsedSong.linesMap[i] == null ||
                parsedSong.linesMap[i]!.trim().isEmpty) {
              List<Text> rowChildren = [];
              for (var chord in parsedSong.chordsMap[i] ?? []) {
                rowChildren.add(
                  Text(tp.transposeChord(chord.name), style: ls.getChordTextStyle(colorScheme.primary)),
                );
              }
              sectionChildren.add(Row(spacing: 5, children: rowChildren));
            } else {
              /// LINES WITH BOTH CHORDS AND LYRICS

              /// PRECEDING CHORD SECTION
              if (parsedSong.hasPrecedingChord) {
                /// SEPARATE PRECEDING CHORDS OF THE LINE
                List<Widget> precedingChords = [];
                int index = parsedSong.chordsMap[i]!.length;
                for (int j = 0; j < parsedSong.chordsMap[i]!.length; j++) {
                  final chord = parsedSong.chordsMap[i]![j];
                  if (chord.lyricsBefore.isEmpty) {
                    precedingChords.add(
                      Text(
                        tp.transposeChord(chord.name),
                        style: ls.getChordTextStyle(colorScheme.primary),
                      ),
                    );
                  } else {
                    index = j;
                    break;
                  }
                }

                /// ADD LINE VIEW WITH REMAINING LINE
                sectionChildren.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.topLeft,
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: parsedSong.precedingChordOffset,
                            height: ls.getChordTextStyle(colorScheme.primary).fontSize!,
                          ),
                          Positioned(
                            top: -ls.lyricTextStyle.fontSize! * 0.8,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 4,
                              children: precedingChords,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: LineView(
                          chords: parsedSong.chordsMap[i]!.sublist(index),
                          line: parsedSong.linesMap[i] ?? '',
                          chordStyle: ls.getChordTextStyle(colorScheme.primary),
                          lyricStyle: ls.lyricTextStyle,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                sectionChildren.add(
                  LineView(
                    chords: parsedSong.chordsMap[i] ?? [],
                    line: parsedSong.linesMap[i] ?? '',
                    chordStyle: ls.getChordTextStyle(colorScheme.primary),
                    lyricStyle: ls.lyricTextStyle,
                  ),
                );
              }
            }
          }
        } else if (ls.showLyrics) {
          /// ONLY LYRICS
          for (int i = 0; i < parsedSong.linesMap.length; i++) {
            sectionChildren.add(
              Text(
                parsedSong.linesMap[i] ?? '',
                style: ls.lyricTextStyle.copyWith(height: 1.2),
              ),
            );
          }
        } else if (ls.showChords) {
          /// ONLY CHORDS
          List<Text> rowChildren = [];
          for (int i = 0; i < parsedSong.chordsMap.length; i++) {
            for (var chord in parsedSong.chordsMap[i]!) {
              rowChildren.add(
                Text(tp.transposeChord(chord.name), style: ls.getChordTextStyle(colorScheme.primary)),
              );
            }
          }
          sectionChildren.add(Wrap(spacing: 5, children: rowChildren));
        }

        return Column(
          children: [
            if (parsedSong.linesMap.isNotEmpty && parsedSong.linesMap.values.every((line) => line.trim().isNotEmpty))
              SizedBox(height: 8),
            Column(
              spacing: ls.lyricTextStyle.fontSize!,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sectionChildren,
            ),
          ],
        );
      },
    );
  }
}
