import 'package:cordis/providers/transposition_provider.dart';
import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChordToken extends StatelessWidget {
  final ContentToken token;
  final Color sectionColor;
  final TextStyle chordStyle;

  const ChordToken({
    super.key,
    required this.token,
    required this.sectionColor,
    required this.chordStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TranspositionProvider>(
      builder: (context, trans, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TokenizationConstants.chordTokenWidthPadding,
            vertical: TokenizationConstants.chordTokenHeightPadding,
          ),
          decoration: BoxDecoration(
            color: sectionColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            trans.transposeChord(token.text),
            textAlign: TextAlign.center,
            style: chordStyle,
          ),
        );
      },
    );
  }
}
