import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';

class ChordToken extends StatelessWidget {
  final ContentToken token;
  final Color sectionColor;
  final TextStyle textStyle;

  const ChordToken({
    super.key,
    required this.token,
    required this.sectionColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 36),
        padding: const EdgeInsets.symmetric(horizontal: TokenizationConstants.chordTokenWidthPadding/2, vertical: TokenizationConstants.chordTokenHeightPadding/2),
        decoration: BoxDecoration(
          color: sectionColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            token.text,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(
              fontSize: textStyle.fontSize! * 0.8,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
