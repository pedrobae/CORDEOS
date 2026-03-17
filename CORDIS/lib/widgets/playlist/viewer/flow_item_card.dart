import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:cordis/providers/playlist/flow_item_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';

import 'package:cordis/utils/date_utils.dart';

import 'package:cordis/widgets/common/custom_reorderable_delayed.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_editor.dart';
import 'package:cordis/widgets/playlist/viewer/flow_item_card_actions.dart';

class FlowItemCard extends StatefulWidget {
  final int flowItemId;
  final int playlistId;
  final int index;

  const FlowItemCard({
    super.key,
    required this.flowItemId,
    required this.playlistId,
    required this.index,
  });

  @override
  State<FlowItemCard> createState() => _FlowItemCardState();
}

class _FlowItemCardState extends State<FlowItemCard> {
  @override
  void initState() {
    super.initState();

    final flow = context.read<FlowItemProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await flow.loadFlowItem(widget.flowItemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Consumer<FlowItemProvider>(
      builder: (context, flow, child) {
        final flowItem = flow.getFlowItem(widget.flowItemId);

        if (flowItem == null || flow.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: colorScheme.surfaceContainerLowest),
          ),
          padding: const EdgeInsets.only(left: 8),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              CustomReorderableDelayed(
                key: widget.key,
                delay: Duration(milliseconds: 100),
                index: widget.index,
                child: Icon(Icons.drag_indicator),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(
                        color: colorScheme.surfaceContainerLowest,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flowItem.title,
                                  style: textTheme.titleMedium,
                                ),
                                Text(
                                  DateTimeUtils.formatDuration(
                                    flowItem.duration,
                                  ),
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _openFlowActionsSheet(context);
                            },
                            icon: Icon(Icons.more_vert_rounded, size: 30),
                          ),
                        ],
                      ),
                      FilledTextButton(
                        text: AppLocalizations.of(context)!.viewPlaceholder(
                          AppLocalizations.of(context)!.flowItem,
                        ),
                        isDense: true,
                        isDiscrete: true,
                        onPressed: () {
                          nav.push(
                            () => FlowItemEditor(
                              playID: widget.playlistId,
                              flowID: widget.flowItemId,
                            ),
                            changeDetector: () => flow.hasPendingChanges,
                            showBottomNavBar: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFlowActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FlowItemCardActionsSheet(
          flowItemId: widget.flowItemId,
          playlistId: widget.playlistId,
        );
      },
    );
  }
}
