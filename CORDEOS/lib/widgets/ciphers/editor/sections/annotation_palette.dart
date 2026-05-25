import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/widgets/ciphers/editor/sections/chord_token.dart';

class AnnotationPalette extends StatefulWidget {
  const AnnotationPalette({super.key});
  @override
  State<AnnotationPalette> createState() => _AnnotationPaletteState();
}

class _AnnotationPaletteState extends State<AnnotationPalette> {
  final TextEditingController _annotationController = TextEditingController();
  String annotation = '';
  bool onLyric = false;

  @override
  void initState() {
    super.initState();
    _annotationController.addListener(() {
      setState(() {
        annotation = _annotationController.text;
      });
    });
  }

  @override
  void dispose() {
    _annotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
        children: [
          // HEADER
          Text(l10n.annotations, style: textTheme.titleMedium),
          // CUSTOM CHORD INPUT
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // CUSTOM CHORD
              if (annotation.isNotEmpty) _buildDraggableAnnotation(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    label: Text(l10n.annotations),
                    labelStyle: textTheme.titleMedium,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    floatingLabelStyle: textTheme.titleMedium,
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
                  controller: _annotationController,
                  expands: false,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(l10n.chords, style: textTheme.titleSmall),
              Switch(
                inactiveThumbColor: colorScheme.secondary,
                activeThumbColor: colorScheme.surfaceContainer,
                trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.secondary;
                  }
                  return colorScheme.surfaceContainer;
                }),
                value: onLyric,
                onChanged: (value) {
                  setState(() {
                    onLyric = value;
                  });
                },
              ),
              Text(l10n.lyrics, style: textTheme.titleSmall),
            ],
          ),
          // Instruction text
          Text(
            l10n.draggableInstruction,
            style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.onLineToggleInstruction,
            style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Draggable<ContentToken> _buildDraggableAnnotation() {
    final laySet = context.read<LayoutSetProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final token = ContentToken(
      text: annotation,
      type: onLyric ? TokenType.lyricAnnotation : TokenType.chordAnnotation,
    );

    final painter = TextPainter(
      text: TextSpan(text: annotation, style: laySet.lyricStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final textHeight = painter.size.height;

    return Draggable<ContentToken>(
      data: token,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: .5),
            shape: BoxShape.circle,
          ),
          width: 10,
          height: 10,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: ChordToken(
          token: token,
          sectionColor: colorScheme.secondary.withValues(alpha: .5),
          chordStyle: laySet.annotationStyle,
          textColor: colorScheme.surface,
        ),
      ),
      feedbackOffset: Offset(0, -textHeight),
      dragAnchorStrategy: (draggable, context, position) =>
          Offset(5, textHeight),
      child: ChordToken(
        token: token,
        sectionColor: colorScheme.secondary,
        textColor: colorScheme.surface,
        chordStyle: laySet.annotationStyle,
      ),
    );
  }
}
