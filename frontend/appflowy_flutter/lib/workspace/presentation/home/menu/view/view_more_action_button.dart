import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/move_to/move_page_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ··· button beside the view name
class ViewMoreActionButton extends StatelessWidget {
  const ViewMoreActionButton({
    super.key,
    required this.view,
    required this.onEditing,
    required this.onAction,
    required this.spaceType,
    required this.isExpanded,
  });

  final ViewPB view;
  final void Function(bool value) onEditing;
  final void Function(ViewMoreActionType type, dynamic data) onAction;
  final FolderSpaceType spaceType;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final wrappers = _buildActionTypeWrappers();
    return PopoverActionList<ViewMoreActionTypeWrapper>(
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 8),
      actions: wrappers,
      constraints: const BoxConstraints(
        minWidth: 260,
      ),
      buildChild: (popover) {
        return FlowyIconButton(
          width: 24,
          icon: const FlowySvg(FlowySvgs.workspace_three_dots_s),
          onPressed: () {
            onEditing(true);
            popover.show();
          },
        );
      },
      onSelected: (_, __) {},
      onClosed: () => onEditing(false),
    );
  }

  List<ViewMoreActionTypeWrapper> _buildActionTypeWrappers() {
    final actionTypes = _buildActionTypes();
    return actionTypes
        .map(
          (e) => ViewMoreActionTypeWrapper(e, view, (controller, data) {
            onEditing(false);
            onAction(e, data);
            controller.close();
          }),
        )
        .toList();
  }

  List<ViewMoreActionType> _buildActionTypes() {
    final List<ViewMoreActionType> actionTypes = [];

    if (spaceType == FolderSpaceType.favorite) {
      actionTypes.addAll([
        ViewMoreActionType.unFavorite,
        ViewMoreActionType.divider,
        ViewMoreActionType.rename,
        ViewMoreActionType.openInNewTab,
      ]);
    } else {
      actionTypes.add(
        view.isFavorite
            ? ViewMoreActionType.unFavorite
            : ViewMoreActionType.favorite,
      );

      actionTypes.addAll([
        ViewMoreActionType.divider,
        ViewMoreActionType.rename,
      ]);

      // Chat doesn't change icon and duplicate
      if (view.layout != ViewLayoutPB.Chat) {
        actionTypes.addAll([
          ViewMoreActionType.changeIcon,
          ViewMoreActionType.duplicate,
        ]);
      }

      actionTypes.addAll([
        ViewMoreActionType.moveTo,
        ViewMoreActionType.delete,
        ViewMoreActionType.divider,
      ]);

      // Chat doesn't change collapse
      // Only show collapse all pages if the view has child views
      if (view.layout != ViewLayoutPB.Chat &&
          view.childViews.isNotEmpty &&
          isExpanded) {
        actionTypes.add(ViewMoreActionType.collapseAllPages);
        actionTypes.add(ViewMoreActionType.divider);
      }

      actionTypes.add(ViewMoreActionType.openInNewTab);
    }

    return actionTypes;
  }
}

class ViewMoreActionTypeWrapper extends CustomActionCell {
  ViewMoreActionTypeWrapper(
    this.inner,
    this.sourceView,
    this.onTap,
  );

  final ViewMoreActionType inner;
  final ViewPB sourceView;
  final void Function(PopoverController controller, dynamic data) onTap;

  @override
  Widget buildWithContext(BuildContext context, PopoverController controller) {
    if (inner == ViewMoreActionType.divider) {
      return _buildDivider();
    } else if (inner == ViewMoreActionType.lastModified) {
      return _buildLastModified(context);
    } else if (inner == ViewMoreActionType.created) {
      return _buildCreated(context);
    } else if (inner == ViewMoreActionType.changeIcon) {
      return _buildEmojiActionButton(context, controller);
    } else if (inner == ViewMoreActionType.moveTo) {
      return _buildMoveToActionButton(context, controller);
    }

    return _buildNormalActionButton(context, controller);
  }

  Widget _buildNormalActionButton(
    BuildContext context,
    PopoverController controller,
  ) {
    return _buildActionButton(context, () => onTap(controller, null));
  }

  Widget _buildEmojiActionButton(
    BuildContext context,
    PopoverController controller,
  ) {
    final child = _buildActionButton(context, null);

    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(364, 356)),
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      clickHandler: PopoverClickHandler.gestureDetector,
      popupBuilder: (_) => FlowyIconPicker(
        onSelected: (result) => onTap(controller, result),
      ),
      child: child,
    );
  }

  Widget _buildMoveToActionButton(
    BuildContext context,
    PopoverController controller,
  ) {
    final child = _buildActionButton(context, null);
    final userProfile = context.read<SpaceBloc>().userProfile;
    final workspaceId = context.read<SpaceBloc>().state.currentSpace?.id;

    return AppFlowyPopover(
      constraints: const BoxConstraints(
        maxWidth: 260,
        maxHeight: 345,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 12.0,
      ),
      clickHandler: PopoverClickHandler.gestureDetector,
      popupBuilder: (_) {
        if (workspaceId == null) {
          return const SizedBox();
        }

        return MovePageMenu(
          sourceView: sourceView,
          userProfile: userProfile,
          workspaceId: workspaceId,
          onSelected: (space, view) {
            onTap(controller, (space, view));
          },
        );
      },
      child: child,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: FlowyDivider(),
    );
  }

  Widget _buildLastModified(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Widget _buildCreated(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    VoidCallback? onTap,
  ) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: FlowyIconTextButton(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        onTap: onTap,
        // show the error color when delete is hovered
        leftIconBuilder: (onHover) => FlowySvg(
          inner.leftIconSvg,
          color: inner == ViewMoreActionType.delete && onHover
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        rightIconBuilder: (_) => inner.rightIcon,
        iconPadding: 10.0,
        textBuilder: (onHover) => FlowyText.regular(
          inner.name,
          color: inner == ViewMoreActionType.delete && onHover
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
    );
  }
}
