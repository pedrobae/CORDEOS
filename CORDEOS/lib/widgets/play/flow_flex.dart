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

    return Selector2<
      FlowItemProvider,
      LayoutSetProvider,
      (FlowItem?, TextStyle)
    >(
      selector: (context, flow, laySet) {
        final fItem = flowItem ?? flow.getFlowItem(flowID!);
        return (fItem, laySet.lyricStyle);
      },
      builder: (context, value, child) {
        final (flowItem, lyricStyle) = value;
        if (flowItem == null) {
          return Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(flowItem.title, style: textTheme.titleMedium),
                Text(
                  '${AppLocalizations.of(context)!.estimatedTime}: ${DateTimeUtils.formatDuration(flowItem.duration)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                border: Border.fromBorderSide(
                  BorderSide(
                    color: colorScheme.surfaceContainerHigh,
                    width: 1.2,
                  ),
                ),
              ),
              child: Text(flowItem.contentText, style: lyricStyle),
            ),
          ],
        );
      },
    );
  }
}
