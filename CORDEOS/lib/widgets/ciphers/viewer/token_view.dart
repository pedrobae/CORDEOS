import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/token_cache_provider.dart';

import 'package:cordeos/services/tokenization/helper_classes.dart';

import 'package:cordeos/utils/token_cache_keys.dart';

class TokenView extends StatelessWidget {
  final TokenCacheKey tokensKey;
  final Color contentColor;

  const TokenView({
    super.key,
    required this.tokensKey,
    required this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokenProv = context.read<TokenProvider>();
    final laySet = context.read<LayoutSetProvider>();

    final colorScheme = Theme.of(context).colorScheme;
    
    tokensKey.lyricColor = colorScheme.onSurface;
    tokensKey.chordColor = colorScheme.primary;

    // PHASE 4a: Retrieve paint instructions from cache and render with CustomPainter
    tokenProv.cachePaintInstructions(
      tokensKey,
      laySet.lyricStyle,
      laySet.chordStyle,
    );

    final model = tokenProv.getPaintModel(tokensKey);

    if (model == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: model.size.height,
      child: CustomPaint(painter: SectionPainter(model: model)),
    );
  }
}

class SectionPainter extends CustomPainter {
  final SectionPaintModel model;

  SectionPainter({required this.model});

  @override
  void paint(Canvas canvas, Size size) {
    for (final token in model.textInstructions) {
      token.painter.paint(canvas, token.offset);
    }

    final paint = Paint()
      ..color = model.underlineColor
      ..strokeWidth = 1;

    for (final underline in model.underlines) {
      canvas.drawLine(
        Offset(underline.offset.dx, underline.offset.dy),
        Offset(underline.offset.dx + underline.width, underline.offset.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SectionPainter oldDelegate) {
    return oldDelegate.model != model;
  }
}
