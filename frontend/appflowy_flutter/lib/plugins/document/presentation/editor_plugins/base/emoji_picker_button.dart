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
    this.emojiPickerSize = const Size(360, 380),
    this.emojiSize = 18.0,
    this.defaultIcon,
    this.offset,
    this.direction,
    this.title,
  });

  final String emoji;
  final double emojiSize;
  final Size emojiPickerSize;
  final void Function(String emoji, PopoverController? controller) onSubmitted;
  final PopoverController popoverController = PopoverController();
  final Widget? defaultIcon;
  final Offset? offset;
  final PopoverDirection? direction;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        controller: popoverController,
        constraints: BoxConstraints.expand(
          width: emojiPickerSize.width,
          height: emojiPickerSize.height,
        ),
        offset: offset,
        direction: direction ?? PopoverDirection.rightWithTopAligned,
        popupBuilder: (context) => Container(
          width: emojiPickerSize.width,
          height: emojiPickerSize.height,
          padding: const EdgeInsets.all(4.0),
          child: EmojiSelectionMenu(
            onSubmitted: (emoji) => onSubmitted(emoji, popoverController),
            onExit: () {},
          ),
        ),
        child: emoji.isEmpty && defaultIcon != null
            ? FlowyButton(
                useIntrinsicWidth: true,
                text: defaultIcon!,
                onTap: () => popoverController.show(),
              )
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
            Uri(
              path: MobileEmojiPickerScreen.routeName,
              queryParameters: {
                MobileEmojiPickerScreen.pageTitle: title,
              },
            ).toString(),
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
