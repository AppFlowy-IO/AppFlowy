import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

typedef SharedPageActionsButtonCallback = void Function(
  ViewMoreActionType type,
  ViewPB view,
  dynamic data,
);

typedef SharedPageActionsButtonSetEditingCallback = void Function(
  BuildContext context,
  bool value,
);

class SharedPageActionsButton extends StatefulWidget {
  const SharedPageActionsButton({
    super.key,
    required this.view,
    required this.accessLevel,
    required this.onAction,
    required this.buildChild,
    required this.onSetEditing,
    this.showAtCursor = false,
  });

  final ViewPB view;
  final ShareAccessLevel accessLevel;
  final SharedPageActionsButtonCallback onAction;
  final SharedPageActionsButtonSetEditingCallback onSetEditing;
  final bool showAtCursor;
  final Widget Function(AFPopoverController) buildChild;

  @override
  State<SharedPageActionsButton> createState() =>
      _SharedPageActionsButtonState();
}

class _SharedPageActionsButtonState extends State<SharedPageActionsButton> {
  AFPopoverController controller = AFPopoverController();

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      if (!controller.isOpen) {
        widget.onSetEditing(context, false);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AFPopover(
      controller: controller,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(), // the AFMenu has a border
      anchor: const AFAnchorAuto(
        offset: Offset(-8, 116),
        followerAnchor: Alignment.centerRight,
        targetAnchor: Alignment.centerLeft,
      ),
      popover: (context) => AFMenu(
        width: 240,
        children: _buildMenuItems(context),
      ),
      child: widget.buildChild(controller),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final actionTypes = _buildActionTypes();
    final menuItems = <Widget>[];

    for (final actionType in actionTypes) {
      if (actionType == ViewMoreActionType.divider) {
        if (menuItems.isNotEmpty) {
          menuItems.add(const AFDivider(spacing: 4));
        }
      } else {
        menuItems.add(
          AFTextMenuItem(
            leading: FlowySvg(
              actionType.leftIconSvg,
              size: const Size.square(16),
              color: actionType == ViewMoreActionType.delete
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            title: actionType.name,
            titleColor: actionType == ViewMoreActionType.delete
                ? Theme.of(context).colorScheme.error
                : null,
            trailing: actionType.rightIcon,
            onTap: () {
              widget.onAction(actionType, widget.view, null);
              controller.hide();
            },
          ),
        );
      }
    }

    return menuItems;
  }

  List<ViewMoreActionType> _buildActionTypes() {
    final List<ViewMoreActionType> actionTypes = [];

    // Always allow add to favorites and open in new tab
    actionTypes.add(
      widget.view.isFavorite
          ? ViewMoreActionType.unFavorite
          : ViewMoreActionType.favorite,
    );

    // Only show editable actions if access level allows it
    if (widget.accessLevel != ShareAccessLevel.readOnly) {
      actionTypes.addAll([
        ViewMoreActionType.divider,
        ViewMoreActionType.rename,
      ]);

      // Chat doesn't change icon and duplicate
      if (widget.view.layout != ViewLayoutPB.Chat) {
        actionTypes.addAll([
          ViewMoreActionType.changeIcon,
        ]);
      }

      if (widget.accessLevel == ShareAccessLevel.fullAccess) {
        actionTypes.addAll([
          ViewMoreActionType.delete,
        ]);
      }
    }

    actionTypes.add(ViewMoreActionType.divider);
    actionTypes.add(ViewMoreActionType.openInNewTab);

    return actionTypes;
  }
}
