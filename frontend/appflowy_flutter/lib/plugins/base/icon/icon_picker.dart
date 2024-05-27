import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/icon.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

extension ToProto on FlowyIconType {
  ViewIconTypePB toProto() {
    switch (this) {
      case FlowyIconType.emoji:
        return ViewIconTypePB.Emoji;
      case FlowyIconType.icon:
        return ViewIconTypePB.Icon;
      case FlowyIconType.custom:
        return ViewIconTypePB.Url;
    }
  }
}

enum FlowyIconType {
  emoji,
  icon,
  custom;
}

class EmojiPickerResult {
  factory EmojiPickerResult.none() =>
      const EmojiPickerResult(FlowyIconType.icon, '');

  factory EmojiPickerResult.emoji(String emoji) =>
      EmojiPickerResult(FlowyIconType.emoji, emoji);

  const EmojiPickerResult(
    this.type,
    this.emoji,
  );

  final FlowyIconType type;
  final String emoji;
}

class FlowyIconPicker extends StatelessWidget {
  const FlowyIconPicker({
    super.key,
    required this.onSelected,
  });

  final void Function(EmojiPickerResult result) onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VSpace(8.0),
          Row(
            children: [
              FlowyText(LocaleKeys.newSettings_workplace_chooseAnIcon.tr()),
              const Spacer(),
              _RemoveIconButton(
                onTap: () => onSelected(EmojiPickerResult.none()),
              ),
            ],
          ),
          const VSpace(12.0),
          const Divider(height: 0.5),
          Expanded(
            child: FlowyEmojiPicker(
              emojiPerLine: _getEmojiPerLine(context),
              onEmojiSelected: (_, emoji) =>
                  onSelected(EmojiPickerResult.emoji(emoji)),
            ),
          ),
        ],
      ),
    );
  }

  int _getEmojiPerLine(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      return 9;
    }
    final width = MediaQuery.of(context).size.width;
    return width ~/ 40.0; // the size of the emoji
  }
}

class _RemoveIconButton extends StatelessWidget {
  const _RemoveIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: FlowyButton(
        onTap: onTap,
        useIntrinsicWidth: true,
        text: FlowyText.regular(
          LocaleKeys.button_remove.tr(),
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
