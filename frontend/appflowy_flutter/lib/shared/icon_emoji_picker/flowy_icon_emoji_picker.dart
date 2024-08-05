import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
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

class FlowyIconEmojiPicker extends StatefulWidget {
  const FlowyIconEmojiPicker({
    super.key,
    required this.onSelected,
  });

  final void Function(EmojiPickerResult result) onSelected;

  @override
  State<FlowyIconEmojiPicker> createState() => _FlowyIconEmojiPickerState();
}

class _FlowyIconEmojiPickerState extends State<FlowyIconEmojiPicker>
    with SingleTickerProviderStateMixin {
  late final controller = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 46,
          padding: const EdgeInsets.only(left: 4.0, right: 12.0),
          child: Row(
            children: [
              Expanded(
                child: PickerTab(
                  controller: controller,
                  tabs: const [
                    PickerTabType.emoji,
                    PickerTabType.icon,
                  ],
                ),
              ),
              _RemoveIconButton(
                onTap: () => widget.onSelected(EmojiPickerResult.none()),
              ),
            ],
          ),
        ),
        const FlowyDivider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FlowyEmojiPicker(
              emojiPerLine: _getEmojiPerLine(context),
              onEmojiSelected: (_, emoji) =>
                  widget.onSelected(EmojiPickerResult.emoji(emoji)),
            ),
          ),
        ),
      ],
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
      height: 32,
      child: FlowyButton(
        onTap: onTap,
        useIntrinsicWidth: true,
        text: FlowyText(
          fontSize: 14.0,
          figmaLineHeight: 16.0,
          fontWeight: FontWeight.w500,
          LocaleKeys.button_remove.tr(),
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
