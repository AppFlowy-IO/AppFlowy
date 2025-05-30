import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

class WorkspaceIcon extends StatefulWidget {
  const WorkspaceIcon({
    super.key,
    required this.workspaceIcon,
    required this.workspaceName,
    required this.iconSize,
    required this.isEditable,
    required this.fontSize,
    required this.onSelected,
    required this.borderRadius,
    required this.emojiSize,
    required this.figmaLineHeight,
    this.showBorder = true,
  });

  final String workspaceIcon;
  final String workspaceName;
  final double iconSize;
  final bool isEditable;
  final double fontSize;
  final double? emojiSize;
  final void Function(EmojiIconData) onSelected;
  final double borderRadius;
  final double figmaLineHeight;
  final bool showBorder;

  @override
  State<WorkspaceIcon> createState() => _WorkspaceIconState();
}

class _WorkspaceIconState extends State<WorkspaceIcon> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    final (textColor, backgroundColor) =
        ColorGenerator(widget.workspaceName).randomColor();

    Widget child = widget.workspaceIcon.isNotEmpty
        ? FlowyText.emoji(
            widget.workspaceIcon,
            fontSize: widget.emojiSize,
            figmaLineHeight: widget.figmaLineHeight,
            optimizeEmojiAlign: true,
          )
        : FlowyText.semibold(
            widget.workspaceName.isEmpty
                ? ''
                : widget.workspaceName.substring(0, 1),
            fontSize: widget.fontSize,
            color: textColor,
          );

    child = Container(
      alignment: Alignment.center,
      width: widget.iconSize,
      height: widget.iconSize,
      decoration: BoxDecoration(
        color: widget.workspaceIcon.isEmpty ? backgroundColor : null,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.showBorder
            ? Border.all(color: const Color(0x1A717171))
            : null,
      ),
      child: child,
    );

    if (widget.isEditable) {
      child = _buildEditableIcon(child);
    }

    return child;
  }

  Widget _buildEditableIcon(Widget child) {
    if (UniversalPlatform.isDesktopOrWeb) {
      return AppFlowyPopover(
        offset: const Offset(0, 8),
        controller: controller,
        direction: PopoverDirection.bottomWithLeftAligned,
        constraints: BoxConstraints.loose(const Size(364, 356)),
        clickHandler: PopoverClickHandler.gestureDetector,
        margin: const EdgeInsets.all(0),
        popupBuilder: (_) => FlowyIconEmojiPicker(
          tabs: const [PickerTabType.emoji],
          onSelectedEmoji: (r) {
            widget.onSelected(r.data);
            if (!r.keepOpen) {
              controller.close();
            }
          },
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: child,
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final result = await context.push<EmojiIconData>(
          Uri(
            path: MobileEmojiPickerScreen.routeName,
            queryParameters: {
              MobileEmojiPickerScreen.pageTitle:
                  LocaleKeys.settings_workspacePage_workspaceIcon_title.tr(),
              MobileEmojiPickerScreen.selectTabs: [PickerTabType.emoji.name],
            },
          ).toString(),
        );
        if (result != null) {
          widget.onSelected(result);
        }
      },
      child: child,
    );
  }
}
