import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/icon.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;

import 'icon.dart';

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
    this.onSelectedEmoji,
    this.onSelectedIcon,
    this.tabs = const [PickerTabType.emoji],
  });

  final void Function(EmojiPickerResult result)? onSelectedEmoji;
  final void Function(IconGroup? group, Icon? icon, String? color)?
      onSelectedIcon;
  final List<PickerTabType> tabs;

  @override
  State<FlowyIconEmojiPicker> createState() => _FlowyIconEmojiPickerState();
}

class _FlowyIconEmojiPickerState extends State<FlowyIconEmojiPicker>
    with SingleTickerProviderStateMixin {
  late final controller = TabController(
    length: widget.tabs.length,
    vsync: this,
  );
  int currentIndex = 0;

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
                  tabs: widget.tabs,
                  onTap: (index) => currentIndex = index,
                ),
              ),
              _RemoveIconButton(
                onTap: () {
                  final currentTab = widget.tabs[currentIndex];
                  if (currentTab == PickerTabType.emoji) {
                    widget.onSelectedEmoji?.call(
                      EmojiPickerResult.none(),
                    );
                  } else {
                    widget.onSelectedIcon?.call(null, null, null);
                  }
                },
              ),
            ],
          ),
        ),
        const FlowyDivider(),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: widget.tabs.map((tab) {
              switch (tab) {
                case PickerTabType.emoji:
                  return _buildEmojiPicker();
                case PickerTabType.icon:
                  return _buildIconPicker();
              }
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: FlowyEmojiPicker(
          emojiPerLine: _getEmojiPerLine(context),
          onEmojiSelected: (_, emoji) => widget.onSelectedEmoji?.call(
            EmojiPickerResult.emoji(emoji),
          ),
        ),
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

  Widget _buildIconPicker() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: FlowyIconPicker(
          onSelectedIcon: (iconGroup, icon, color) {
            debugPrint('icon: ${icon.toJson()}, color: $color');
            widget.onSelectedIcon?.call(iconGroup, icon, color);
          },
        ),
      ),
    );
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
