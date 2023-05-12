import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class OptionActionList extends StatelessWidget {
  const OptionActionList({
    Key? key,
    required this.blockComponentState,
  }) : super(key: key);

  final BlockComponentState blockComponentState;

  @override
  Widget build(BuildContext context) {
    final actions = [
      OptionAction.delete,
      OptionAction.duplicate,
      OptionAction.turnInto,
      OptionAction.divider,
      OptionAction.moveUp,
      OptionAction.moveDown,
      OptionAction.divider,
      OptionAction.color,
    ]
        .map(
          (e) => e == OptionAction.divider
              ? DividerOptionAction()
              : OptionActionWrapper(e),
        )
        .toList();

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.leftWithCenterAligned,
      offset: const Offset(0, 0),
      actions: actions,
      onPopupBuilder: () => blockComponentState.alwaysShowActions = true,
      onClosed: () => blockComponentState.alwaysShowActions = false,
      buildChild: (controller) => Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => controller.show(),
          child: svgWidget(
            'editor/option',
            size: const Size.square(24.0),
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
      onSelected: (action, controller) async {
        controller.close();
      },
    );
  }
}

class BlockComponentActionButton extends StatelessWidget {
  const BlockComponentActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final bool isHovering = false;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: (details) {},
        onTapUp: (details) {},
        child: icon,
      ),
    );
  }
}

class OptionActionButton extends StatefulWidget {
  const OptionActionButton({
    super.key,
    required this.blockComponentState,
  });

  final BlockComponentState blockComponentState;

  @override
  State<OptionActionButton> createState() => _OptionActionButtonState();
}

class _OptionActionButtonState extends State<OptionActionButton> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      margin: const EdgeInsets.all(0),
      controller: controller,
      onClose: () => widget.blockComponentState.alwaysShowActions = false,
      popupBuilder: (context) {
        widget.blockComponentState.alwaysShowActions = true;
        return Container(
          width: 100,
          height: 100,
          color: Colors.red,
        );
      },
      child: const Icon(
        Icons.apps_rounded,
        size: 18.0,
      ),
    );
  }
}
