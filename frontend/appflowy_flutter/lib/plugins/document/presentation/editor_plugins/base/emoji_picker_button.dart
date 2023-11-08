import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class EmojiPickerButton extends StatelessWidget {
  EmojiPickerButton({
    super.key,
    required this.emoji,
    required this.onSubmitted,
    this.emojiPickerSize = const Size(360, 380),
    this.emojiSize = 18.0,
    this.defaultIcon,
    this.offset,
    this.direction,
  });

  final String emoji;
  final double emojiSize;
  final Size emojiPickerSize;
  final void Function(String emoji, PopoverController controller) onSubmitted;
  final PopoverController popoverController = PopoverController();
  final Widget? defaultIcon;
  final Offset? offset;
  final PopoverDirection? direction;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.click,
      constraints: BoxConstraints.expand(
        width: emojiPickerSize.width,
        height: emojiPickerSize.height,
      ),
      offset: offset,
      direction: direction ?? PopoverDirection.rightWithTopAligned,
      popupBuilder: (context) => _buildEmojiPicker(),
      child: emoji.isEmpty && defaultIcon != null
          ? defaultIcon!
          : FlowyTextButton(
              emoji,
              overflow: TextOverflow.visible,
              fontSize: emojiSize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 35.0),
              fillColor: Colors.transparent,
              mainAxisAlignment: MainAxisAlignment.center,
              onPressed: () {
                popoverController.show();
              },
            ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      width: emojiPickerSize.width,
      height: emojiPickerSize.height,
      padding: const EdgeInsets.all(4.0),
      child: EmojiSelectionMenu(
        onSubmitted: (emoji) {
          onSubmitted(emoji, popoverController);
          popoverController.close();
        },
        onExit: () {},
      ),
    );
  }
}
