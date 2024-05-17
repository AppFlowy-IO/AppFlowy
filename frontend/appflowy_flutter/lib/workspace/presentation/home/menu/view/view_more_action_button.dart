import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

/// ··· button beside the view name
class ViewMoreActionButton extends StatelessWidget {
  const ViewMoreActionButton({
    super.key,
    required this.view,
    required this.onEditing,
    required this.onAction,
    required this.spaceType,
  });

  final ViewPB view;
  final void Function(bool value) onEditing;
  final void Function(ViewMoreActionType) onAction;
  final FolderSpaceType spaceType;

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
          (e) => ViewMoreActionTypeWrapper(e, (controller) {
            onEditing(false);
            onAction(e);
            controller.close();
          }),
        )
        .toList();
  }

  List<ViewMoreActionType> _buildActionTypes() {
    final List<ViewMoreActionType> actionTypes = [];
    switch (spaceType) {
      case FolderSpaceType.favorite:
        actionTypes.addAll([
          ViewMoreActionType.unFavorite,
          ViewMoreActionType.divider,
          ViewMoreActionType.rename,
          ViewMoreActionType.openInNewTab,
        ]);
        break;
      default:
        actionTypes.addAll([
          view.isFavorite
              ? ViewMoreActionType.unFavorite
              : ViewMoreActionType.favorite,
          ViewMoreActionType.divider,
          ViewMoreActionType.rename,
          ViewMoreActionType.changeIcon,
          ViewMoreActionType.duplicate,
          ViewMoreActionType.delete,
          ViewMoreActionType.divider,
          ViewMoreActionType.collapseAllPages,
          ViewMoreActionType.divider,
          ViewMoreActionType.openInNewTab,
        ]);
    }
    return actionTypes;
  }
}

class ViewMoreActionTypeWrapper extends CustomActionCell {
  ViewMoreActionTypeWrapper(this.inner, this.onTap);

  final ViewMoreActionType inner;
  final void Function(PopoverController controller) onTap;

  @override
  Widget buildWithContext(BuildContext context, PopoverController controller) {
    if (inner == ViewMoreActionType.divider) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Divider(height: 1.0),
      );
    }

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        leftIcon: inner.leftIcon,
        rightIcon: inner.rightIcon,
        iconPadding: 10.0,
        text: SizedBox(
          height: 18.0,
          child: FlowyText.regular(
            inner.name,
            color: inner == ViewMoreActionType.delete
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
        onTap: () => onTap(controller),
      ),
    );
  }
}
