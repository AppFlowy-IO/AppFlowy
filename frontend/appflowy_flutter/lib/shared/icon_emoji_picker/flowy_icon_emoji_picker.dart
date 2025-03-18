import 'dart:math';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/icon.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

import 'icon_uploader.dart';

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

extension FlowyIconTypeToPickerTabType on FlowyIconType {
  PickerTabType? toPickerTabType() => name.toPickerTabType();
}

class EmojiIconData {
  factory EmojiIconData.none() => const EmojiIconData(FlowyIconType.icon, '');

  factory EmojiIconData.emoji(String emoji) =>
      EmojiIconData(FlowyIconType.emoji, emoji);

  factory EmojiIconData.icon(IconsData icon) =>
      EmojiIconData(FlowyIconType.icon, icon.iconString);

  factory EmojiIconData.custom(String url) =>
      EmojiIconData(FlowyIconType.custom, url);

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

class SelectedEmojiIconResult {
  SelectedEmojiIconResult(this.data, this.keepOpen);

  final EmojiIconData data;
  final bool keepOpen;

  FlowyIconType get type => data.type;

  String get emoji => data.emoji;
}

extension EmojiIconDataToViewIconPBExtension on EmojiIconData {
  ViewIconPB toViewIconPB() {
    switch (type) {
      case FlowyIconType.emoji:
        return ViewIconPB()
          ..ty = ViewIconTypePB.Emoji
          ..value = emoji;
      case FlowyIconType.icon:
        return ViewIconPB()
          ..ty = ViewIconTypePB.Icon
          ..value = emoji;
      case FlowyIconType.custom:
        return ViewIconPB()
          ..ty = ViewIconTypePB.Url
          ..value = emoji;
    }
  }
}

extension EmojiIconDataToSelectedResultExtension on EmojiIconData {
  SelectedEmojiIconResult toSelectedResult({bool keepOpen = false}) =>
      SelectedEmojiIconResult(this, keepOpen);
}

class FlowyIconEmojiPicker extends StatefulWidget {
  const FlowyIconEmojiPicker({
    super.key,
    this.onSelectedEmoji,
    this.initialType,
    this.documentId,
    this.enableBackgroundColorSelection = true,
    this.tabs = const [
      PickerTabType.emoji,
      PickerTabType.icon,
    ],
  });

  final ValueChanged<SelectedEmojiIconResult>? onSelectedEmoji;
  final bool enableBackgroundColorSelection;
  final List<PickerTabType> tabs;
  final PickerTabType? initialType;
  final String? documentId;

  @override
  State<FlowyIconEmojiPicker> createState() => _FlowyIconEmojiPickerState();
}

class _FlowyIconEmojiPickerState extends State<FlowyIconEmojiPicker>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final initialType = widget.initialType;
    if (initialType != null) {
      currentIndex = max(widget.tabs.indexOf(initialType), 0);
    }
    controller = TabController(
      initialIndex: currentIndex,
      length: widget.tabs.length,
      vsync: this,
    );
    controller.addListener(() {
      final currentType = widget.tabs[currentIndex];
      if (currentType == PickerTabType.custom) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
  }

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
                  widget.onSelectedEmoji
                      ?.call(EmojiIconData.none().toSelectedResult());
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
                case PickerTabType.custom:
                  return _buildIconUploader();
              }
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return FlowyEmojiPicker(
      ensureFocus: true,
      emojiPerLine: _getEmojiPerLine(context),
      onEmojiSelected: (r) {
        widget.onSelectedEmoji?.call(
          EmojiIconData.emoji(r.emoji).toSelectedResult(keepOpen: r.isRandom),
        );
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
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
      ensureFocus: true,
      enableBackgroundColorSelection: widget.enableBackgroundColorSelection,
      onSelectedIcon: (r) {
        widget.onSelectedEmoji?.call(
          r.data.toEmojiIconData().toSelectedResult(keepOpen: r.isRandom),
        );
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
    );
  }

  Widget _buildIconUploader() {
    return IconUploader(
      documentId: widget.documentId ?? '',
      ensureFocus: true,
      onUrl: (url) {
        widget.onSelectedEmoji
            ?.call(SelectedEmojiIconResult(EmojiIconData.custom(url), false));
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
