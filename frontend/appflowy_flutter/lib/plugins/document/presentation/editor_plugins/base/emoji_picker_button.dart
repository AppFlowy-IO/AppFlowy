import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmojiPickerButton extends StatelessWidget {
  EmojiPickerButton({
    super.key,
    required this.emoji,
    required this.onSubmitted,
    this.emojiPickerSize = const Size(300, 250),
    this.emojiSize = 18.0,
  });

  final String emoji;
  final double emojiSize;
  final Size emojiPickerSize;
  final void Function(String emoji, PopoverController? controller) onSubmitted;
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        controller: popoverController,
        triggerActions: PopoverTriggerFlags.click,
        constraints: BoxConstraints.expand(
          width: emojiPickerSize.width,
          height: emojiPickerSize.height,
        ),
        popupBuilder: (context) => Container(
          width: emojiPickerSize.width,
          height: emojiPickerSize.height,
          padding: const EdgeInsets.all(4.0),
          child: EmojiSelectionMenu(
            onSubmitted: (emoji) => onSubmitted(emoji, popoverController),
            onExit: () {},
          ),
        ),
        child: FlowyTextButton(
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
    } else {
      return FlowyTextButton(
        emoji,
        overflow: TextOverflow.visible,
        fontSize: emojiSize,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 35.0),
        fillColor: Colors.transparent,
        mainAxisAlignment: MainAxisAlignment.center,
        onPressed: () async {
          final result = await context.push<EmojiPickerResult>(
            MobileEmojiPickerScreen.routeName,
          );
          if (result != null) {
            onSubmitted(
              result.emoji,
              null,
            );
          }
        },
      );
    }
  }
}
