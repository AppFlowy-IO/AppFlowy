import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class PopoverActionList<T extends PopoverAction> extends StatefulWidget {
  final List<T> actions;
  final PopoverMutex? mutex;
  final Function(T, PopoverController) onSelected;
  final BoxConstraints constraints;
  final PopoverDirection direction;
  final Widget Function(PopoverController) buildChild;
  final VoidCallback? onClosed;
  final bool asBarrier;

  const PopoverActionList({
    required this.actions,
    required this.buildChild,
    required this.onSelected,
    this.mutex,
    this.onClosed,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.asBarrier = false,
    this.constraints = const BoxConstraints(
      minWidth: 120,
      maxWidth: 460,
      maxHeight: 300,
    ),
    Key? key,
  }) : super(key: key);

  @override
  State<PopoverActionList<T>> createState() => _PopoverActionListState<T>();
}

class _PopoverActionListState<T extends PopoverAction>
    extends State<PopoverActionList<T>> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.buildChild(popoverController);

    return AppFlowyPopover(
      asBarrier: widget.asBarrier,
      controller: popoverController,
      constraints: widget.constraints,
      direction: widget.direction,
      mutex: widget.mutex,
      triggerActions: PopoverTriggerFlags.none,
      onClose: widget.onClosed,
      popupBuilder: (BuildContext popoverContext) {
        final List<Widget> children = widget.actions.map((action) {
          if (action is ActionCell) {
            return ActionCellWidget<T>(
              action: action,
              itemHeight: ActionListSizes.itemHeight,
              onSelected: (action) {
                widget.onSelected(action, popoverController);
              },
            );
          } else {
            final custom = action as CustomActionCell;
            return custom.buildWithContext(context);
          }
        }).toList();

        return IntrinsicHeight(
          child: IntrinsicWidth(
            child: Column(
              children: children,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

abstract class ActionCell extends PopoverAction {
  Widget? leftIcon(Color iconColor) => null;
  Widget? rightIcon(Color iconColor) => null;
  String get name;
}

abstract class CustomActionCell extends PopoverAction {
  Widget buildWithContext(BuildContext context);
}

abstract class PopoverAction {}

class ActionListSizes {
  static double itemHPadding = 10;
  static double itemHeight = 20;
  static double vPadding = 6;
  static double hPadding = 10;
}

class ActionCellWidget<T extends PopoverAction> extends StatelessWidget {
  final T action;
  final Function(T) onSelected;
  final double itemHeight;
  const ActionCellWidget({
    Key? key,
    required this.action,
    required this.onSelected,
    required this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionCell = action as ActionCell;
    final leftIcon =
        actionCell.leftIcon(Theme.of(context).colorScheme.onSurface);

    final rightIcon =
        actionCell.rightIcon(Theme.of(context).colorScheme.onSurface);

    return FlowyHover(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(action),
        child: SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              if (leftIcon != null) ...[
                leftIcon,
                HSpace(ActionListSizes.itemHPadding)
              ],
              Expanded(
                child: FlowyText.medium(
                  actionCell.name,
                  overflow: TextOverflow.visible,
                ),
              ),
              if (rightIcon != null) ...[
                HSpace(ActionListSizes.itemHPadding),
                rightIcon,
              ],
            ],
          ),
        ).padding(
          horizontal: ActionListSizes.hPadding,
          vertical: ActionListSizes.vPadding,
        ),
      ),
    );
  }
}
