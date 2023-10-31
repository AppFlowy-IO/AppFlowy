import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:emoji_mart/emoji_mart.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FlowyEmojiSkinToneSelector extends StatefulWidget {
  const FlowyEmojiSkinToneSelector({
    super.key,
    required this.onEmojiSkinToneChanged,
  });

  final EmojiSkinToneChanged onEmojiSkinToneChanged;

  @override
  State<FlowyEmojiSkinToneSelector> createState() =>
      _FlowyEmojiSkinToneSelectorState();
}

class _FlowyEmojiSkinToneSelectorState
    extends State<FlowyEmojiSkinToneSelector> {
  EmojiSkinTone skinTone = EmojiSkinTone.none;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<EmojiSkinToneWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 8),
      actions: EmojiSkinTone.values
          .map((action) => EmojiSkinToneWrapper(action))
          .toList(),
      buildChild: (controller) {
        return SizedBox.square(
          dimension: 32,
          child: FlowyButton(
            text: const Icon(
              Icons.emoji_emotions,
              size: 20,
            ),
            useIntrinsicWidth: true,
            onTap: () => controller.show(),
          ),
        );
      },
      onSelected: (action, controller) async {
        widget.onEmojiSkinToneChanged(action.inner);
        controller.close();
      },
    );
  }
}

class EmojiSkinToneWrapper extends ActionCell {
  EmojiSkinToneWrapper(this.inner);

  final EmojiSkinTone inner;

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    // TODO: i18n
    return inner.toString();
  }
}
