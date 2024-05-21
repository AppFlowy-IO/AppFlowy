import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

// use a temporary global value to store last selected skin tone
EmojiSkinTone? lastSelectedEmojiSkinTone;

@visibleForTesting
ValueKey emojiSkinToneKey(String icon) {
  return ValueKey('emoji_skin_tone_$icon');
}

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
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithCenterAligned,
      controller: controller,
      popupBuilder: (context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: EmojiSkinTone.values
              .map(
                (e) => _buildIconButton(
                  e.icon,
                  () {
                    setState(() => lastSelectedEmojiSkinTone = e);
                    widget.onEmojiSkinToneChanged(e);
                    controller.close();
                  },
                ),
              )
              .toList(),
        );
      },
      child: FlowyTooltip(
        message: LocaleKeys.emoji_selectSkinTone.tr(),
        child: _buildIconButton(
          lastSelectedEmojiSkinTone?.icon ?? '👋',
          () => controller.show(),
        ),
      ),
    );
  }

  Widget _buildIconButton(String icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x1E171717)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FlowyButton(
        key: emojiSkinToneKey(icon),
        expandText: false,
        // ensure the emoji is centered
        margin: const EdgeInsets.only(top: 6),
        text: FlowyText.emoji(
          icon,
          fontSize: 24.0,
        ),
        onTap: onPressed,
      ),
    );
  }
}

extension EmojiSkinToneIcon on EmojiSkinTone {
  String get icon {
    switch (this) {
      case EmojiSkinTone.none:
        return '👋';
      case EmojiSkinTone.light:
        return '👋🏻';
      case EmojiSkinTone.mediumLight:
        return '👋🏼';
      case EmojiSkinTone.medium:
        return '👋🏽';
      case EmojiSkinTone.mediumDark:
        return '👋🏾';
      case EmojiSkinTone.dark:
        return '👋🏿';
    }
  }
}
