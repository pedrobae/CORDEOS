import 'package:cordeos/models/domain/playlist/flow_item.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cordeos/providers/playlist/flow_item_provider.dart';
import 'package:cordeos/providers/navigation_provider.dart';

import 'package:cordeos/utils/date_utils.dart';

import 'package:cordeos/widgets/common/custom_reorderable_delayed.dart';
import 'package:cordeos/widgets/playlist/viewer/flow_item_editor.dart';
import 'package:cordeos/widgets/playlist/viewer/flow_item_card_actions.dart';

class FlowItemCard extends StatefulWidget {
  final int flowItemID;
  final int playlistID;
  final int index;
  final bool canEdit;

  const FlowItemCard({
    super.key,
    required this.flowItemID,
    required this.playlistID,
    required this.index,
    required this.canEdit,
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
      await flow.loadFlowItem(widget.flowItemID);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final nav = context.read<NavigationProvider>();

    return Selector<FlowItemProvider, FlowItem?>(
      selector: (context, flow) => flow.getFlowItem(widget.flowItemID),
      builder: (context, flowItem, child) {
        if (flowItem == null) {
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
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.canEdit)
                CustomReorderableDelayed(
                  delay: Duration(milliseconds: 100),
                  index: widget.index,
                  child: Container(
                    // Container to paint and enable hitbox for the icon
                    color: Colors.transparent,
                    height: 60,
                    child: Icon(Icons.drag_indicator, size: 30),
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final flow = context.read<FlowItemProvider>();
                    nav.push(
                      () => FlowItemEditor(
                        playlistID: widget.playlistID,
                        flowID: widget.flowItemID,
                        canEdit: widget.canEdit,
                      ),
                      changeDetector: widget.canEdit
                          ? () => flow.hasUnsavedChanges
                          : null,
                      onChangeDiscarded: widget.canEdit
                          ? () => flow.loadFlowItem(widget.flowItemID)
                          : null,
                      showBottomNavBar: true,
                    );
                  },
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(flowItem.title, style: textTheme.titleMedium),
                            Text(
                              DateTimeUtils.formatDuration(flowItem.duration),
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.canEdit)
                GestureDetector(
                  onTap: () {
                    _openFlowActionsSheet(context);
                  },
                  child: Container(
                    // Container to paint and enable hitbox for the icon
                    color: Colors.transparent,
                    height: 60,
                    child: Icon(Icons.more_vert_rounded, size: 30),
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
          flowItemId: widget.flowItemID,
          playlistId: widget.playlistID,
        );
      },
    );
  }
}
