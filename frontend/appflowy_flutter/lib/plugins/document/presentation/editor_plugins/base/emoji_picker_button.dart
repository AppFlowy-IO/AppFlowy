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
    this.showBorder = true,
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
  final bool showBorder;

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
        popupBuilder: (_) => Container(
          width: emojiPickerSize.width,
          height: emojiPickerSize.height,
          padding: const EdgeInsets.all(4.0),
          child: EmojiSelectionMenu(
            onSubmitted: (emoji) => onSubmitted(emoji, popoverController),
            onExit: () {},
          ),
        ),
        child: Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            color: const Color(0x0F1F2329),
            borderRadius: BorderRadius.circular(8),
            border: showBorder
                ? Border.all(
                    color: Theme.of(context).dividerColor,
                  )
                : null,
          ),
          child: FlowyButton(
            margin: emoji.isEmpty && defaultIcon != null
                ? EdgeInsets.zero
                : const EdgeInsets.only(left: 2.0),
            expandText: false,
            text: emoji.isEmpty && defaultIcon != null
                ? defaultIcon!
                : FlowyText.emoji(emoji, fontSize: emojiSize),
            onTap: popoverController.show,
          ),
        ),
      );
    }
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
            queryParameters: {MobileEmojiPickerScreen.pageTitle: title},
          ).toString(),
        );
        if (result != null) {
          onSubmitted(result.emoji, null);
        }
      },
    );
  }
}
