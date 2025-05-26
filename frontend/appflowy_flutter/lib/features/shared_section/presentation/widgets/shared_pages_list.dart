import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

typedef SharedPageViewMoreActionCallback = void Function(
  ViewMoreActionType type,
  ViewPB view,
  dynamic data,
);

typedef SharedPageSetEditingCallback = void Function(
  BuildContext context,
  bool value,
);

class SharedPagesList extends StatelessWidget {
  const SharedPagesList({
    super.key,
    required this.sharedPages,
    required this.onAction,
    required this.onSelected,
    required this.onTertiarySelected,
    required this.onSetEditing,
  });

  final SharedPages sharedPages;
  final SharedPageViewMoreActionCallback onAction;
  final ViewItemOnSelected onSelected;
  final ViewItemOnSelected onTertiarySelected;
  final SharedPageSetEditingCallback onSetEditing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sharedPages.map((sharedPage) {
        final view = sharedPage.view;
        final accessLevel = sharedPage.accessLevel;
        return ViewItem(
          key: ValueKey(view.id),
          spaceType: FolderSpaceType.public,
          isFirstChild: view.id == sharedPages.first.view.id,
          view: view,
          level: 0,
          isDraggable: false, // disable draggable for shared pages
          leftPadding: HomeSpaceViewSizes.leftPadding,
          isFeedback: false,
          onSelected: onSelected,
          onTertiarySelected: onTertiarySelected,
          rightIconsBuilder: (context, view) => [
            IntrinsicWidth(
              child: _buildSharedPageMoreActionButton(
                context,
                view,
                accessLevel,
              ),
            ),
            const SizedBox(width: 4.0),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSharedPageMoreActionButton(
    BuildContext context,
    ViewPB view,
    ShareAccessLevel accessLevel,
  ) {
    return SharedPageViewMoreActionPopover(
      view: view,
      accessLevel: accessLevel,
      onAction: onAction,
      onSetEditing: onSetEditing,
      buildChild: (controller) => FlowyIconButton(
        width: 24,
        icon: const FlowySvg(FlowySvgs.workspace_three_dots_s),
        onPressed: () {
          onSetEditing(context, true);
          controller.show();
        },
      ),
    );
  }
}

class SharedPageViewMoreActionPopover extends StatefulWidget {
  const SharedPageViewMoreActionPopover({
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
  final SharedPageViewMoreActionCallback onAction;
  final Widget Function(AFPopoverController) buildChild;
  final SharedPageSetEditingCallback onSetEditing;
  final bool showAtCursor;

  @override
  State<SharedPageViewMoreActionPopover> createState() =>
      _SharedPageViewMoreActionPopoverState();
}

class _SharedPageViewMoreActionPopoverState
    extends State<SharedPageViewMoreActionPopover> {
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
          ViewMoreActionType.duplicate,
        ]);
      }

      if (widget.accessLevel == ShareAccessLevel.fullAccess) {
        actionTypes.addAll([
          ViewMoreActionType.moveTo,
          ViewMoreActionType.delete,
        ]);
      }
    }

    actionTypes.add(ViewMoreActionType.divider);
    actionTypes.add(ViewMoreActionType.openInNewTab);

    return actionTypes;
  }
}
