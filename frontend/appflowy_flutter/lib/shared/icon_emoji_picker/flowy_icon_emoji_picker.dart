import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/icon.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;
import 'package:universal_platform/universal_platform.dart';

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

extension FromProto on ViewIconTypePB {
  FlowyIconType fromProto() {
    switch (this) {
      case ViewIconTypePB.Emoji:
        return FlowyIconType.emoji;
      case ViewIconTypePB.Icon:
        return FlowyIconType.icon;
      case ViewIconTypePB.Url:
        return FlowyIconType.custom;
      default:
        return FlowyIconType.custom;
    }
  }
}

extension ToEmojiIconData on ViewIconPB {
  EmojiIconData toEmojiIconData() => EmojiIconData(ty.fromProto(), value);
}

enum FlowyIconType {
  emoji,
  icon,
  custom;
}

class EmojiIconData {
  factory EmojiIconData.none() => const EmojiIconData(FlowyIconType.icon, '');

  factory EmojiIconData.emoji(String emoji) =>
      EmojiIconData(FlowyIconType.emoji, emoji);

  factory EmojiIconData.icon(IconsData icon) =>
      EmojiIconData(FlowyIconType.icon, icon.iconString);

  const EmojiIconData(
    this.type,
    this.emoji,
  );

  final FlowyIconType type;
  final String emoji;

  static EmojiIconData fromViewIconPB(ViewIconPB v) {
    return EmojiIconData(v.ty.fromProto(), v.value);
  }

  ViewIconPB toViewIcon() {
    return ViewIconPB()
      ..ty = type.toProto()
      ..value = emoji;
  }

  bool get isEmpty => emoji.isEmpty;

  bool get isNotEmpty => emoji.isNotEmpty;
}

class FlowyIconEmojiPicker extends StatefulWidget {
  const FlowyIconEmojiPicker({
    super.key,
    this.onSelectedEmoji,
    this.enableBackgroundColorSelection = true,
    this.tabs = const [PickerTabType.emoji, PickerTabType.icon],
  });

  final ValueChanged<EmojiIconData>? onSelectedEmoji;
  final bool enableBackgroundColorSelection;
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
                  widget.onSelectedEmoji?.call(EmojiIconData.none());
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
    return FlowyEmojiPicker(
      emojiPerLine: _getEmojiPerLine(context),
      onEmojiSelected: (_, emoji) => widget.onSelectedEmoji?.call(
        EmojiIconData.emoji(emoji),
      ),
    );
  }

  int _getEmojiPerLine(BuildContext context) {
    if (UniversalPlatform.isDesktopOrWeb) {
      return 9;
    }
    final width = MediaQuery.of(context).size.width;
    return width ~/ 40.0; // the size of the emoji
  }

  Widget _buildIconPicker() {
    return FlowyIconPicker(
      enableBackgroundColorSelection: widget.enableBackgroundColorSelection,
      onSelectedIcon: (result) {
        widget.onSelectedEmoji?.call(result.toEmojiIconData());
      },
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
