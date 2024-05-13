import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RenameViewPopover extends StatefulWidget {
  const RenameViewPopover({
    super.key,
    required this.viewId,
    required this.name,
    required this.popoverController,
    required this.emoji,
    this.icon,
    this.showIconChanger = true,
  });

  final String viewId;
  final String name;
  final PopoverController popoverController;
  final String emoji;
  final Widget? icon;
  final bool showIconChanger;

  @override
  State<RenameViewPopover> createState() => _RenameViewPopoverState();
}

class _RenameViewPopoverState extends State<RenameViewPopover> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.name;
    _controller.selection =
        TextSelection(baseOffset: 0, extentOffset: widget.name.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIconChanger) ...[
          SizedBox(
            width: 32.0,
            child: EmojiPickerButton(
              emoji: widget.emoji,
              defaultIcon: widget.icon,
              direction: PopoverDirection.bottomWithCenterAligned,
              offset: const Offset(0, 18),
              onSubmitted: _updateViewIcon,
            ),
          ),
          const HSpace(6),
        ],
        SizedBox(
          height: 36.0,
          width: 220,
          child: FlowyTextField(
            controller: _controller,
            maxLength: 256,
            onSubmitted: _updateViewName,
            onCanceled: () => _updateViewName(_controller.text),
            showCounter: false,
          ),
        ),
      ],
    );
  }

  Future<void> _updateViewName(String name) async {
    if (name.isNotEmpty && name != widget.name) {
      await ViewBackendService.updateView(
        viewId: widget.viewId,
        name: _controller.text,
      );
      widget.popoverController.close();
    }
  }

  Future<void> _updateViewIcon(String emoji, PopoverController? _) async {
    await ViewBackendService.updateViewIcon(
      viewId: widget.viewId,
      viewIcon: emoji,
    );
    widget.popoverController.close();
  }
}
