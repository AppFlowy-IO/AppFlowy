import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_mart/emoji_mart.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

// use a temporary global value to store last selected skin tone
EmojiSkinTone? lastSelectedEmojiSkinTone;

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
        return FlowyTooltip(
          message: LocaleKeys.emoji_selectSkinTone.tr(),
          child: FlowyIconButton(
            icon: Padding(
              // add a left padding to align the emoji center
              padding: const EdgeInsets.only(
                left: 3.0,
              ),
              child: FlowyText(
                lastSelectedEmojiSkinTone?.icon ?? '✋',
                fontSize: 22.0,
              ),
            ),
            onPressed: () => controller.show(),
          ),
        );
      },
      onSelected: (action, controller) async {
        widget.onEmojiSkinToneChanged(action.inner);
        setState(() {
          lastSelectedEmojiSkinTone = action.inner;
        });
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
    final String i18n;
    switch (inner) {
      case EmojiSkinTone.none:
        i18n = LocaleKeys.emoji_skinTone_default.tr();
      case EmojiSkinTone.light:
        i18n = LocaleKeys.emoji_skinTone_light.tr();
      case EmojiSkinTone.mediumLight:
        i18n = LocaleKeys.emoji_skinTone_mediumLight.tr();
      case EmojiSkinTone.medium:
        i18n = LocaleKeys.emoji_skinTone_medium.tr();
      case EmojiSkinTone.mediumDark:
        i18n = LocaleKeys.emoji_skinTone_mediumDark.tr();
      case EmojiSkinTone.dark:
        i18n = LocaleKeys.emoji_skinTone_dark.tr();
    }
    return '${inner.icon} $i18n';
  }
}

extension on EmojiSkinTone {
  String get icon {
    switch (this) {
      case EmojiSkinTone.none:
        return '✋';
      case EmojiSkinTone.light:
        return '✋🏻';
      case EmojiSkinTone.mediumLight:
        return '✋🏼';
      case EmojiSkinTone.medium:
        return '✋🏽';
      case EmojiSkinTone.mediumDark:
        return '✋🏾';
      case EmojiSkinTone.dark:
        return '✋🏿';
    }
  }
}
