import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedPagesList extends StatelessWidget {
  const SharedPagesList({
    super.key,
    required this.sharedPages,
  });

  final SharedPages sharedPages;

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
          onSelected: (context, view) {
            if (HardwareKeyboard.instance.isControlPressed) {
              context.read<TabsBloc>().openTab(view);
            }
            context.read<TabsBloc>().openPlugin(view);
          },
          onTertiarySelected: (context, view) =>
              context.read<TabsBloc>().openTab(view),
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
      onAction: (action, data) async {
        switch (action) {
          case ViewMoreActionType.favorite:
          case ViewMoreActionType.unFavorite:
            context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view));
            break;
          case ViewMoreActionType.openInNewTab:
            context.read<TabsBloc>().openTab(view);
            break;
          default:
            // Other actions are not allowed for read-only access
            break;
        }
      },
      buildChild: (controller) => FlowyIconButton(
        width: 24,
        icon: const FlowySvg(FlowySvgs.workspace_three_dots_s),
        onPressed: () {
          context.read<ViewBloc>().add(const ViewEvent.setIsEditing(true));
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
    this.showAtCursor = false,
  });

  final ViewPB view;
  final ShareAccessLevel accessLevel;
  final void Function(ViewMoreActionType type, dynamic data) onAction;
  final Widget Function(AFPopoverController) buildChild;
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
        context.read<ViewBloc>().add(const ViewEvent.setIsEditing(false));
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
        offset: Offset(0, 62),
        followerAnchor: Alignment.centerRight,
        targetAnchor: Alignment.centerLeft,
      ),
      popover: (context) => AFMenu(
        width: 260,
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
              widget.onAction(actionType, null);
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

    actionTypes.add(ViewMoreActionType.divider);
    actionTypes.add(ViewMoreActionType.openInNewTab);

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

    return actionTypes;
  }
}
