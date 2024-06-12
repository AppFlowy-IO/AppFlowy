import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_action_type.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SpaceMorePopup extends StatelessWidget {
  const SpaceMorePopup({
    super.key,
    required this.space,
    required this.onAction,
    required this.onEditing,
  });

  final ViewPB space;
  final void Function(SpaceMoreActionType type, dynamic data) onAction;
  final void Function(bool value) onEditing;

  @override
  Widget build(BuildContext context) {
    final wrappers = _buildActionTypeWrappers();
    return PopoverActionList<SpaceMoreActionTypeWrapper>(
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

  List<SpaceMoreActionTypeWrapper> _buildActionTypeWrappers() {
    final actionTypes = _buildActionTypes();
    return actionTypes
        .map(
          (e) => SpaceMoreActionTypeWrapper(e, (controller, data) {
            onAction(e, data);
            controller.close();
          }),
        )
        .toList();
  }

  List<SpaceMoreActionType> _buildActionTypes() {
    return [
      SpaceMoreActionType.rename,
      SpaceMoreActionType.changeIcon,
      SpaceMoreActionType.manage,
      SpaceMoreActionType.divider,
      SpaceMoreActionType.addNewSpace,
      SpaceMoreActionType.collapseAllPages,
      SpaceMoreActionType.divider,
      SpaceMoreActionType.delete,
    ];
  }
}

class SpaceMoreActionTypeWrapper extends CustomActionCell {
  SpaceMoreActionTypeWrapper(this.inner, this.onTap);

  final SpaceMoreActionType inner;
  final void Function(PopoverController controller, dynamic data) onTap;

  @override
  Widget buildWithContext(BuildContext context, PopoverController controller) {
    if (inner == SpaceMoreActionType.divider) {
      return _buildDivider();
    } else if (inner == SpaceMoreActionType.changeIcon) {
      return _buildEmojiActionButton(context, controller);
    } else {
      return _buildNormalActionButton(context, controller);
    }
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
      clickHandler: PopoverClickHandler.gestureDetector,
      popupBuilder: (_) => FlowyIconPicker(
        onSelected: (result) => onTap(controller, result),
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Divider(height: 1.0),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    VoidCallback? onTap,
  ) {
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
            color: inner == SpaceMoreActionType.delete
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
