import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordis/helpers/chords/chords.dart';
import 'package:cordis/widgets/ciphers/editor/sections/chord_token.dart';

double _fontSize = 20;

class ChordPalette extends StatefulWidget {
  final dynamic versionId;

  const ChordPalette({super.key, required this.versionId});
  @override
  State<ChordPalette> createState() => _ChordPaletteState();
}

class _ChordPaletteState extends State<ChordPalette> {
  final TextEditingController _customChordController = TextEditingController();
  String customChord = '';
  final _chordVariationsNotifier = ValueNotifier<List<String>>([]);

  void _showChordVariations(String baseChord, int chordIndex) {
    final chordVariations = ChordHelper().getVariationsForChord(
      baseChord,
      chordIndex,
    );

    if (chordVariations.every(
      (variation) => _chordVariationsNotifier.value.contains(variation),
    )) {
      _chordVariationsNotifier.value = [];
    } else {
      _chordVariationsNotifier.value = chordVariations;
    }
  }

  @override
  void initState() {
    super.initState();
    _customChordController.addListener(() {
      setState(() {
        customChord = _customChordController.text;
      });
    });
  }

  @override
  void dispose() {
    _customChordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranspositionProvider>(
      builder: (context, tp, child) {
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;

        final chords = ChordHelper().getChordsForKey(
          tp.transposedKey ?? tp.originalKey,
        );

        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(),
            boxShadow: [
              BoxShadow(
                color: colorScheme.surfaceContainerLow,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 16,
            children: [
              // HEADER
              Text(
                AppLocalizations.of(context)!.commonChordsOfKey(chords[0]),
                style: textTheme.titleMedium,
              ),
              // CUSTOM CHORD INPUT
              Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // CUSTOM CHORD
                  if (customChord.isNotEmpty)
                    _buildDraggableChordToken(customChord),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context)!.customChord),
                        labelStyle: textTheme.titleMedium,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        floatingLabelStyle: textTheme.titleMedium,
                        hintText: AppLocalizations.of(
                          context,
                        )!.customChordInstruction,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      controller: _customChordController,
                      expands: false,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  ValueListenableBuilder<List<String>>(
                    valueListenable: _chordVariationsNotifier,
                    builder: (context, chordVariations, child) {
                      if (chordVariations.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        margin: const EdgeInsets.only(bottom: 8.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.surfaceContainerLowest,
                            ),
                            bottom: BorderSide(
                              color: colorScheme.surfaceContainerLowest,
                            ),
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final variation in chordVariations)
                              _buildDraggableChordToken(variation),
                          ],
                        ),
                      );
                    },
                  ), // Draggable chords
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (int i = 0; i < chords.length; i++)
                        Builder(
                          builder: (builder) {
                            final chord = chords[i];
                            return GestureDetector(
                              onLongPress: () => {
                                _showChordVariations(chord, i),
                              },
                              child: _buildDraggableChordToken(chord),
                            );
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Instruction text
                  Text(
                    AppLocalizations.of(context)!.draggableChordInstruction,
                    style: textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.chordExpansionInstruction,
                    style: textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Draggable<ContentToken> _buildDraggableChordToken(String chord) {
    final token = ContentToken(text: chord, type: TokenType.chord);
    final colorScheme = Theme.of(context).colorScheme;

    final tp = TextPainter(
      text: TextSpan(
        text: chord,
        style: TextStyle(fontSize: _fontSize),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final size = Size(
      tp.width,
      tp.height
    );

    return Draggable<ContentToken>(
      data: token,
      feedback: Material(
        color: Colors.transparent,
        child: ChordToken(
          token: token,
          tokenSize: size,
          sectionColor: colorScheme.onSurface.withValues(alpha: .7),
          textStyle: TextStyle(fontSize: _fontSize, color: colorScheme.surface),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: ChordToken(
          tokenSize: size,
          token: token,
          sectionColor: colorScheme.onSurface.withValues(alpha: .4),
          textStyle: TextStyle(
            fontSize: _fontSize,
            color: colorScheme.surface.withValues(alpha: .4),
          ),
        ),
      ),
      child: ChordToken(
        tokenSize: size,
        token: token,
        sectionColor: colorScheme.onSurface,
        textStyle: TextStyle(fontSize: _fontSize, color: colorScheme.surface),
      ),
    );
  }
}
