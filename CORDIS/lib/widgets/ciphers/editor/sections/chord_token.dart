import 'package:cordis/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';

class ChordToken extends StatelessWidget {
  final ContentToken token;
  final Size tokenSize;
  final Color sectionColor;
  final TextStyle textStyle;

  const ChordToken({
    super.key,
    required this.token,
    required this.tokenSize,
    required this.sectionColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tokenSize.width + TokenizationConstants.chordTokenWidthPadding,
      height: tokenSize.height + TokenizationConstants.chordTokenHeightPadding,
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
    );
  }
}
