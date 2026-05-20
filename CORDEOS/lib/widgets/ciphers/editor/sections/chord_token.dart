import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';

class ChordToken extends StatelessWidget {
  final ContentToken token;
  final Color sectionColor;
  final Color textColor;
  final TextStyle chordStyle;

  const ChordToken({
    super.key,
    required this.token,
    required this.sectionColor,
    required this.textColor,
    required this.chordStyle,
  });

  @override
  Widget build(BuildContext context) {
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
        token.text,
        textAlign: TextAlign.center,
        style: chordStyle.copyWith(color: textColor),
      ),
    );
  }
}
