import 'dart:math';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

class WorkspaceIcon extends StatefulWidget {
  const WorkspaceIcon({
    super.key,
    required this.workspace,
    required this.enableEdit,
    required this.iconSize,
    required this.fontSize,
    required this.onSelected,
    this.borderRadius = 4,
    this.emojiSize,
    this.alignment,
    required this.figmaLineHeight,
  });

  final UserWorkspacePB workspace;
  final double iconSize;
  final bool enableEdit;
  final double fontSize;
  final double? emojiSize;
  final void Function(EmojiPickerResult) onSelected;
  final double borderRadius;
  final Alignment? alignment;
  final double figmaLineHeight;

  @override
  State<WorkspaceIcon> createState() => _WorkspaceIconState();
}

class _WorkspaceIconState extends State<WorkspaceIcon> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    Widget child = widget.workspace.icon.isNotEmpty
        ? Container(
            width: widget.iconSize,
            alignment: widget.alignment ?? Alignment.center,
            child: FlowyText.emoji(
              widget.workspace.icon,
              fontSize: widget.emojiSize ?? widget.iconSize,
              figmaLineHeight: widget.figmaLineHeight,
              optimizeEmojiAlign: true,
            ),
          )
        : Container(
            alignment: Alignment.center,
            width: widget.iconSize,
            height: min(widget.iconSize, 24),
            decoration: BoxDecoration(
              color: ColorGenerator(widget.workspace.name).toColor(),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: const Color(0xa1717171),
                width: 0.5,
              ),
            ),
            child: FlowyText.semibold(
              widget.workspace.name.isEmpty
                  ? ''
                  : widget.workspace.name.substring(0, 1),
              fontSize: widget.fontSize,
              color: Colors.black,
            ),
          );

    if (widget.enableEdit) {
      child = AppFlowyPopover(
        offset: const Offset(0, 8),
        controller: controller,
        direction: PopoverDirection.bottomWithLeftAligned,
        constraints: BoxConstraints.loose(const Size(364, 356)),
        clickHandler: PopoverClickHandler.gestureDetector,
        margin: const EdgeInsets.all(0),
        popupBuilder: (_) => FlowyIconEmojiPicker(
          onSelectedEmoji: (result) {
            widget.onSelected(result);
            controller.close();
          },
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: child,
        ),
      );
    }
    return child;
  }
}

// The v2 supports the built-in color set
class WorkspaceIconV2 extends StatefulWidget {
  const WorkspaceIconV2({
    super.key,
    required this.workspace,
    required this.enableEdit,
    required this.iconSize,
    required this.fontSize,
    required this.onSelected,
    this.borderRadius = 4,
    this.emojiSize,
    this.alignment,
    required this.figmaLineHeight,
    this.showBorder = true,
  });

  final UserWorkspacePB workspace;
  final double iconSize;
  final bool enableEdit;
  final double fontSize;
  final double? emojiSize;
  final void Function(EmojiPickerResult) onSelected;
  final double borderRadius;
  final Alignment? alignment;
  final double figmaLineHeight;
  final bool showBorder;

  @override
  State<WorkspaceIconV2> createState() => _WorkspaceIconV2State();
}

class _WorkspaceIconV2State extends State<WorkspaceIconV2> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    final color = ColorGenerator(widget.workspace.name).randomColor();
    Widget child = widget.workspace.icon.isNotEmpty
        ? FlowyText.emoji(
            widget.workspace.icon,
            fontSize: widget.emojiSize,
            figmaLineHeight: widget.figmaLineHeight,
            optimizeEmojiAlign: true,
          )
        : FlowyText.semibold(
            widget.workspace.name.isEmpty
                ? ''
                : widget.workspace.name.substring(0, 1),
            fontSize: widget.fontSize,
            color: color.$1,
          );

    child = Container(
      alignment: Alignment.center,
      width: widget.iconSize,
      height: widget.iconSize,
      decoration: BoxDecoration(
        color: widget.workspace.icon.isNotEmpty ? null : color.$2,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.showBorder
            ? Border.all(
                color: const Color(0x1A717171),
              )
            : null,
      ),
      child: child,
    );

    if (widget.enableEdit) {
      child = _buildEditableIcon(child);
    }

    return child;
  }

  Widget _buildEditableIcon(Widget child) {
    if (UniversalPlatform.isDesktopOrWeb) {
      AppFlowyPopover(
        offset: const Offset(0, 8),
        controller: controller,
        direction: PopoverDirection.bottomWithLeftAligned,
        constraints: BoxConstraints.loose(const Size(364, 356)),
        clickHandler: PopoverClickHandler.gestureDetector,
        margin: const EdgeInsets.all(0),
        popupBuilder: (_) => FlowyIconEmojiPicker(
          onSelectedEmoji: (result) {
            widget.onSelected(result);
            controller.close();
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
        final result = await context.push<EmojiPickerResult>(
          Uri(
            path: MobileEmojiPickerScreen.routeName,
            queryParameters: {
              MobileEmojiPickerScreen.pageTitle:
                  LocaleKeys.settings_workspacePage_workspaceIcon_title.tr(),
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
