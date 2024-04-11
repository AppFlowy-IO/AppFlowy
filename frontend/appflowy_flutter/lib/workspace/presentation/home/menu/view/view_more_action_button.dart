import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';

/// ··· button beside the view name
class ViewMoreActionButton extends StatelessWidget {
  const ViewMoreActionButton({
    super.key,
    required this.view,
    required this.onEditing,
    required this.onAction,
  });

  final ViewPB view;
  final void Function(bool value) onEditing;
  final void Function(ViewMoreActionType) onAction;

  @override
  Widget build(BuildContext context) {
    final supportedActionTypes = [
      ViewMoreActionType.rename,
      ViewMoreActionType.delete,
      ViewMoreActionType.duplicate,
      ViewMoreActionType.openInNewTab,
      view.isFavorite
          ? ViewMoreActionType.unFavorite
          : ViewMoreActionType.favorite,
    ];
    return PopoverActionList<ViewMoreActionTypeWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 8),
      actions: supportedActionTypes
          .map((e) => ViewMoreActionTypeWrapper(e))
          .toList(),
      buildChild: (popover) {
        return FlowyIconButton(
          hoverColor: Colors.transparent,
          iconPadding: const EdgeInsets.all(2),
          width: 26,
          icon: const FlowySvg(FlowySvgs.details_s),
          onPressed: () {
            onEditing(true);
            popover.show();
          },
        );
      },
      onSelected: (action, popover) {
        onEditing(false);
        onAction(action.inner);
        popover.close();
      },
      onClosed: () => onEditing(false),
    );
  }
}

class ViewMoreActionTypeWrapper extends ActionCell {
  ViewMoreActionTypeWrapper(this.inner);

  final ViewMoreActionType inner;

  @override
  Widget? leftIcon(Color iconColor) => inner.icon(iconColor);

  @override
  String get name => inner.name;
}
