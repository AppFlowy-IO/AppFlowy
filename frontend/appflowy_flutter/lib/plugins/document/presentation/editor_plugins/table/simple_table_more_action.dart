import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SimpleTableMoreActionType {
  column,
  row;

  List<SimpleTableMoreAction> get actions {
    switch (this) {
      case SimpleTableMoreActionType.column:
        return [
          SimpleTableMoreAction.addColumnBefore,
          SimpleTableMoreAction.addColumnAfter,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContent,
          SimpleTableMoreAction.delete,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.align,
          SimpleTableMoreAction.backgroundColor,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.enableHeaderColumn,
        ];
      case SimpleTableMoreActionType.row:
        return [
          SimpleTableMoreAction.addRowBefore,
          SimpleTableMoreAction.addRowAfter,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContent,
          SimpleTableMoreAction.delete,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.align,
          SimpleTableMoreAction.backgroundColor,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.enableHeaderRow,
        ];
    }
  }
}

enum SimpleTableMoreAction {
  addColumnBefore,
  addColumnAfter,
  addRowBefore,
  addRowAfter,
  duplicate,
  clearContent,
  delete,
  align,
  backgroundColor,
  enableHeaderColumn,
  enableHeaderRow,
  divider;

  String get name {
    return switch (this) {
      SimpleTableMoreAction.align => 'Align',
      SimpleTableMoreAction.backgroundColor => 'Color',
      SimpleTableMoreAction.enableHeaderColumn => 'Enable header column',
      SimpleTableMoreAction.enableHeaderRow => 'Enable header row',
      SimpleTableMoreAction.addColumnBefore => 'Insert above',
      SimpleTableMoreAction.addColumnAfter => 'Insert below',
      SimpleTableMoreAction.addRowAfter => 'Insert left',
      SimpleTableMoreAction.addRowBefore => 'Insert right',
      SimpleTableMoreAction.clearContent => 'Clear content',
      SimpleTableMoreAction.delete => 'Delete',
      SimpleTableMoreAction.duplicate => 'Duplicate',
      SimpleTableMoreAction.divider => throw UnimplementedError(),
    };
  }

  FlowySvgData get leftIconSvg {
    return switch (this) {
      SimpleTableMoreAction.addColumnBefore => FlowySvgs.table_insert_above_s,
      SimpleTableMoreAction.addColumnAfter => FlowySvgs.table_insert_below_s,
      SimpleTableMoreAction.addRowBefore => FlowySvgs.table_insert_right_s,
      SimpleTableMoreAction.addRowAfter => FlowySvgs.table_insert_left_s,
      SimpleTableMoreAction.duplicate => FlowySvgs.duplicate_s,
      SimpleTableMoreAction.clearContent => FlowySvgs.table_clear_content_s,
      SimpleTableMoreAction.delete => FlowySvgs.delete_s,
      SimpleTableMoreAction.divider =>
        throw UnsupportedError('divider icon is not supported'),
      SimpleTableMoreAction.align =>
        throw UnsupportedError('align icon is not supported'),
      SimpleTableMoreAction.backgroundColor =>
        throw UnsupportedError('background color icon is not supported'),
      SimpleTableMoreAction.enableHeaderColumn => throw UnsupportedError(
          'the enable header column icon is not supported',
        ),
      SimpleTableMoreAction.enableHeaderRow =>
        throw UnsupportedError('the enable header row icon is not supported'),
    };
  }
}

class SimpleTableMoreActionMenu extends StatefulWidget {
  const SimpleTableMoreActionMenu({
    super.key,
    required this.index,
    required this.type,
  });

  final int index;
  final SimpleTableMoreActionType type;

  @override
  State<SimpleTableMoreActionMenu> createState() =>
      _SimpleTableMoreActionMenuState();
}

class _SimpleTableMoreActionMenuState extends State<SimpleTableMoreActionMenu> {
  ValueNotifier<bool> isShowingMenu = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.type == SimpleTableMoreActionType.row
          ? Alignment.topCenter
          : Alignment.centerLeft,
      child: ValueListenableBuilder<bool>(
        valueListenable: isShowingMenu,
        builder: (context, isShowingMenu, child) {
          return ValueListenableBuilder(
            valueListenable:
                context.read<SimpleTableContext>().hoveringTableNode,
            builder: (context, hoveringTableNode, child) {
              final hoveringIndex =
                  widget.type == SimpleTableMoreActionType.column
                      ? hoveringTableNode?.cellPosition.$1
                      : hoveringTableNode?.cellPosition.$2;
              debugPrint(
                'hoveringIndex: $hoveringIndex, index: ${widget.index}',
              );

              if (hoveringIndex != widget.index && !isShowingMenu) {
                return const SizedBox.shrink();
              }

              return child!;
            },
            child: AppFlowyPopover(
              onOpen: () => this.isShowingMenu.value = true,
              onClose: () => this.isShowingMenu.value = false,
              direction: widget.type == SimpleTableMoreActionType.row
                  ? PopoverDirection.bottomWithCenterAligned
                  : PopoverDirection.rightWithCenterAligned,
              popupBuilder: (context) => SimpleTableMoreActionList(
                type: widget.type,
              ),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  color: Colors.red,
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SimpleTableMoreActionList extends StatelessWidget {
  const SimpleTableMoreActionList({
    super.key,
    required this.type,
  });

  final SimpleTableMoreActionType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: type.actions
          .map((action) => SimpleTableMoreActionItem(action: action))
          .toList(),
    );
  }
}

class SimpleTableMoreActionItem extends StatelessWidget {
  const SimpleTableMoreActionItem({
    super.key,
    required this.action,
  });

  final SimpleTableMoreAction action;

  @override
  Widget build(BuildContext context) {
    if (action == SimpleTableMoreAction.divider) {
      return _buildDivider(context);
    } else if (action == SimpleTableMoreAction.align) {
      return _buildAlignMenu(context);
    } else if (action == SimpleTableMoreAction.backgroundColor) {
      return _buildBackgroundColorMenu(context);
    } else if (action == SimpleTableMoreAction.enableHeaderColumn) {
      return _buildEnableHeaderButton(context);
    } else if (action == SimpleTableMoreAction.enableHeaderRow) {
      return _buildEnableHeaderButton(context);
    }

    return _buildActionButton(context);
  }

  Widget _buildDivider(BuildContext context) {
    return const FlowyDivider(
      padding: EdgeInsets.symmetric(
        vertical: 4.0,
      ),
    );
  }

  Widget _buildAlignMenu(BuildContext context) {
    return Container(
      height: SimpleTableConstants.moreActionHeight,
      padding: SimpleTableConstants.moreActionPadding,
      child: FlowyButton(
        text: FlowyText.regular(action.name, fontSize: 14.0),
        onTap: () {},
      ),
    );
  }

  Widget _buildBackgroundColorMenu(BuildContext context) {
    return Container(
      height: SimpleTableConstants.moreActionHeight,
      padding: SimpleTableConstants.moreActionPadding,
      child: FlowyButton(
        text: FlowyText.regular(action.name, fontSize: 14.0),
        onTap: () {},
      ),
    );
  }

  Widget _buildEnableHeaderButton(BuildContext context) {
    return Container(
      height: SimpleTableConstants.moreActionHeight,
      padding: SimpleTableConstants.moreActionPadding,
      child: FlowyButton(
        text: FlowyText.regular(action.name, fontSize: 14.0),
        rightIcon: Toggle(
          value: true,
          onChanged: (value) {},
          padding: EdgeInsets.zero,
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      height: SimpleTableConstants.moreActionHeight,
      padding: SimpleTableConstants.moreActionPadding,
      child: FlowyIconTextButton(
        margin: SimpleTableConstants.moreActionHorizontalMargin,
        leftIconBuilder: (onHover) => FlowySvg(
          action.leftIconSvg,
          color: action == SimpleTableMoreAction.delete && onHover
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        iconPadding: 10.0,
        textBuilder: (onHover) => FlowyText.regular(
          action.name,
          fontSize: 14.0,
          lineHeight: 1.0,
          figmaLineHeight: 18.0,
          color: action == SimpleTableMoreAction.delete && onHover
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        onTap: () {},
      ),
    );
  }
}
