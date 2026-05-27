import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/settings/layout_settings_provider.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowFlex extends StatelessWidget {
  final int itemIndex;
  final int? flowID;
  final FlowItem? flowItem;

  /// Requires either [flowID] or [flowItem] to be provided. If both are provided, [flowItem] will be used.
  const FlowFlex({
    super.key,
    required this.itemIndex,
    this.flowID,
    this.flowItem,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final width = MediaQuery.sizeOf(context).width;

    return Selector2<
      FlowItemProvider,
      LayoutSetProvider,
      ({FlowItem? flow, TextStyle lyricStyle, double widthMult})
    >(
      selector: (context, flow, laySet) {
        final fItem = flowItem ?? flow.getFlowItem(flowID!);
        return (
          flow: fItem,
          lyricStyle: laySet.lyricStyle,
          widthMult: laySet.cardWidthMult,
        );
      },
      builder: (context, s, child) {
        if (s.flow == null) {
          return Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.flow!.title, style: textTheme.titleMedium),
                Text(
                  '${AppLocalizations.of(context)!.estimatedTime}: ${DateTimeUtils.formatDuration(s.flow!.duration)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              width: s.widthMult * width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                border: Border.fromBorderSide(
                  BorderSide(
                    color: colorScheme.surfaceContainerHigh,
                    width: 1.2,
                  ),
                ),
              ),
              child: Text(s.flow!.contentText, style: s.lyricStyle),
            ),
          ],
        );
      },
    );
  }
}
