import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart' hide WidgetBuilder;
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class PopoverActionList<T extends PopoverAction> extends StatefulWidget {
  final List<T> actions;
  final PopoverMutex? mutex;
  final Function(T, PopoverController) onSelected;
  final BoxConstraints constraints;
  final PopoverDirection direction;
  final Widget Function(PopoverController) buildChild;
  final VoidCallback? onPopupBuilder;
  final VoidCallback? onClosed;
  final bool asBarrier;
  final Offset offset;

  const PopoverActionList({
    required this.actions,
    required this.buildChild,
    required this.onSelected,
    this.mutex,
    this.onClosed,
    this.onPopupBuilder,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.asBarrier = false,
    this.offset = Offset.zero,
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
      offset: widget.offset,
      triggerActions: PopoverTriggerFlags.none,
      onClose: widget.onClosed,
      popupBuilder: (BuildContext popoverContext) {
        widget.onPopupBuilder?.call();
        final List<Widget> children = widget.actions.map((action) {
          if (action is ActionCell) {
            return ActionCellWidget<T>(
              action: action,
              itemHeight: ActionListSizes.itemHeight,
              onSelected: (action) {
                widget.onSelected(action, popoverController);
              },
            );
          } else if (action is PopoverActionCell) {
            return PopoverActionCellWidget<T>(
              popoverController: popoverController,
              action: action,
              itemHeight: ActionListSizes.itemHeight,
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

typedef PopoverActionCellBuilder = Widget Function(
  BuildContext context,
  PopoverController parentController,
  PopoverController controller,
);

abstract class PopoverActionCell extends PopoverAction {
  Widget? leftIcon(Color iconColor) => null;
  Widget? rightIcon(Color iconColor) => null;
  String get name;

  PopoverActionCellBuilder get builder;
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

    return HoverButton(
      itemHeight: itemHeight,
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      name: actionCell.name,
      onTap: () => onSelected(action),
    );
  }
}

class PopoverActionCellWidget<T extends PopoverAction> extends StatefulWidget {
  const PopoverActionCellWidget({
    super.key,
    required this.popoverController,
    required this.action,
    required this.itemHeight,
  });

  final T action;
  final double itemHeight;

  final PopoverController popoverController;

  @override
  State<PopoverActionCellWidget> createState() =>
      _PopoverActionCellWidgetState();
}

class _PopoverActionCellWidgetState<T extends PopoverAction>
    extends State<PopoverActionCellWidget<T>> {
  final popoverController = PopoverController();
  @override
  Widget build(BuildContext context) {
    final actionCell = widget.action as PopoverActionCell;
    final leftIcon =
        actionCell.leftIcon(Theme.of(context).colorScheme.onSurface);
    final rightIcon =
        actionCell.rightIcon(Theme.of(context).colorScheme.onSurface);
    return AppFlowyPopover(
      controller: popoverController,
      asBarrier: true,
      popupBuilder: (context) => actionCell.builder(
        context,
        widget.popoverController,
        popoverController,
      ),
      child: HoverButton(
        itemHeight: widget.itemHeight,
        leftIcon: leftIcon,
        rightIcon: rightIcon,
        name: actionCell.name,
        onTap: () => popoverController.show(),
      ),
    );
  }
}

class HoverButton extends StatelessWidget {
  const HoverButton({
    super.key,
    required this.onTap,
    required this.itemHeight,
    required this.leftIcon,
    required this.name,
    required this.rightIcon,
  });

  final VoidCallback onTap;
  final double itemHeight;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final String name;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              if (leftIcon != null) ...[
                leftIcon!,
                HSpace(ActionListSizes.itemHPadding)
              ],
              Expanded(
                child: FlowyText.medium(
                  name,
                  overflow: TextOverflow.visible,
                ),
              ),
              if (rightIcon != null) ...[
                HSpace(ActionListSizes.itemHPadding),
                rightIcon!,
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
