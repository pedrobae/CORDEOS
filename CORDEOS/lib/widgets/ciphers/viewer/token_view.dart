import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TokenView extends StatelessWidget {
  final TokenCacheKey layoutKey;
  final Color contentColor;

  const TokenView({
    super.key,
    required this.layoutKey,
    required this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final provider = context.read<TokenProvider>();
    final laySet = context.read<LayoutSetProvider>();

    // Phase 4: Build widgets (not cached - uses positions cache)
    final content = provider.buildViewWidgets(
      key: layoutKey,
      lyricStyle: laySet.lyricTextStyle,
      chordStyle: laySet.chordTextStyle,
      textColor: colorScheme.surface,
      chordColor: colorScheme.primary,
    );

    return SizedBox(
      height: content.contentHeight,
      child: Stack(clipBehavior: Clip.none, children: content.tokens),
    );
  }
}
