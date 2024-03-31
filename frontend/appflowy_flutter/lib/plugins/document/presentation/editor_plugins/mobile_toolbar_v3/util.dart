import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileToolbarMenuItemWrapper extends StatelessWidget {
  const MobileToolbarMenuItemWrapper({
    super.key,
    required this.size,
    this.icon,
    this.text,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.enable,
    this.fontFamily,
    required this.isSelected,
    required this.iconPadding,
    this.enableBottomLeftRadius = true,
    this.enableBottomRightRadius = true,
    this.enableTopLeftRadius = true,
    this.enableTopRightRadius = true,
    this.showDownArrow = false,
    this.showRightArrow = false,
    this.textPadding = EdgeInsets.zero,
    required this.onTap,
    this.iconColor,
  });

  final Size size;
  final VoidCallback onTap;
  final FlowySvgData? icon;
  final String? text;
  final bool? enable;
  final String? fontFamily;
  final bool isSelected;
  final EdgeInsets iconPadding;
  final bool enableTopLeftRadius;
  final bool enableTopRightRadius;
  final bool enableBottomRightRadius;
  final bool enableBottomLeftRadius;
  final bool showDownArrow;
  final bool showRightArrow;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final EdgeInsets textPadding;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    Color? iconColor = this.iconColor;
    if (iconColor == null) {
      if (enable != null) {
        iconColor = enable! ? null : theme.toolbarMenuIconDisabledColor;
      } else {
        iconColor = isSelected
            ? theme.toolbarMenuIconSelectedColor
            : theme.toolbarMenuIconColor;
      }
    }
    final textColor =
        enable == false ? theme.toolbarMenuIconDisabledColor : null;
    // the ui design is based on 375.0 width
    final scale = context.scale;
    final radius = Radius.circular(12 * scale);
    final Widget child;
    if (icon != null) {
      child = FlowySvg(
        icon!,
        color: iconColor,
      );
    } else if (text != null) {
      child = Padding(
        padding: textPadding * scale,
        child: FlowyText(
          text!,
          fontSize: 16.0,
          color: textColor,
          fontFamily: fontFamily,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      throw ArgumentError('icon and text cannot be null at the same time');
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enable == false ? null : onTap,
      child: Stack(
        children: [
          Container(
            height: size.height * scale,
            width: size.width * scale,
            alignment: text != null ? Alignment.centerLeft : Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? (selectedBackgroundColor ??
                      theme.toolbarMenuItemSelectedBackgroundColor)
                  : backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: enableTopLeftRadius ? radius : Radius.zero,
                topRight: enableTopRightRadius ? radius : Radius.zero,
                bottomRight: enableBottomRightRadius ? radius : Radius.zero,
                bottomLeft: enableBottomLeftRadius ? radius : Radius.zero,
              ),
            ),
            padding: iconPadding * scale,
            child: child,
          ),
          if (showDownArrow)
            Positioned(
              right: 9.0 * scale,
              bottom: 9.0 * scale,
              child: const FlowySvg(FlowySvgs.m_aa_down_arrow_s),
            ),
          if (showRightArrow)
            Positioned.fill(
              right: 12.0 * scale,
              child: Align(
                alignment: Alignment.centerRight,
                child: FlowySvg(
                  FlowySvgs.m_aa_arrow_right_s,
                  color: iconColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScaledVerticalDivider extends StatelessWidget {
  const ScaledVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return HSpace(
      1.5 * context.scale,
    );
  }
}

class ScaledVSpace extends StatelessWidget {
  const ScaledVSpace({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return VSpace(12.0 * context.scale);
  }
}

extension MobileToolbarBuildContext on BuildContext {
  double get scale => MediaQuery.of(this).size.width / 375.0;
}

final _blocksCanContainChildren = [
  ParagraphBlockKeys.type,
  BulletedListBlockKeys.type,
  NumberedListBlockKeys.type,
  TodoListBlockKeys.type,
];

extension MobileToolbarEditorState on EditorState {
  bool isBlockTypeSelected(
    String blockType, {
    int? level,
  }) {
    final selection = this.selection;
    if (selection == null) {
      return false;
    }
    final node = getNodeAtPath(selection.start.path);
    final type = node?.type;
    if (node == null || type == null) {
      return false;
    }
    if (level != null && blockType == HeadingBlockKeys.type) {
      return type == blockType &&
          node.attributes[HeadingBlockKeys.level] == level;
    }
    return type == blockType;
  }

  bool isTextDecorationSelected(
    String richTextKey,
  ) {
    final selection = this.selection;
    if (selection == null) {
      return false;
    }

    final nodes = getNodesInSelection(selection);
    bool isSelected = false;
    if (selection.isCollapsed) {
      if (toggledStyle.containsKey(richTextKey)) {
        isSelected = toggledStyle[richTextKey] as bool;
      } else {
        if (selection.startIndex != 0) {
          // get previous index text style
          isSelected = nodes.allSatisfyInSelection(
              selection.copyWith(
                start: selection.start.copyWith(
                  offset: selection.startIndex - 1,
                ),
              ), (delta) {
            return delta.everyAttributes(
              (attributes) => attributes[richTextKey] == true,
            );
          });
        }
      }
    } else {
      isSelected = nodes.allSatisfyInSelection(selection, (delta) {
        return delta.everyAttributes(
          (attributes) => attributes[richTextKey] == true,
        );
      });
    }
    return isSelected;
  }

  Future<void> convertBlockType(
    String newBlockType, {
    Selection? selection,
    Attributes? extraAttributes,
    bool? isSelected,
    Map? selectionExtraInfo,
  }) async {
    selection = selection ?? this.selection;
    if (selection == null) {
      return;
    }
    final node = getNodeAtPath(selection.start.path);
    final type = node?.type;
    if (node == null || type == null) {
      assert(false, 'node or type is null');
      return;
    }
    final selected = isSelected ?? type == newBlockType;

    // if the new block type can't contain children, we need to move all the children to the parent
    bool needToDeleteChildren = false;
    if (!selected &&
        node.children.isNotEmpty &&
        !_blocksCanContainChildren.contains(newBlockType)) {
      final transaction = this.transaction;
      needToDeleteChildren = true;
      transaction.insertNodes(
        selection.end.path.next,
        node.children.map((e) => e.copyWith()),
      );
      await apply(transaction);
    }
    await formatNode(
      selection,
      (node) {
        final attributes = {
          ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
          // for some block types, they have extra attributes, like todo list has checked attribute, callout has icon attribute, etc.
          if (!selected && extraAttributes != null) ...extraAttributes,
        };
        return node.copyWith(
          type: selected ? ParagraphBlockKeys.type : newBlockType,
          attributes: attributes,
          children: needToDeleteChildren ? [] : null,
        );
      },
      selectionExtraInfo: selectionExtraInfo,
    );
  }

  Future<void> alignBlock(
    String alignment, {
    Selection? selection,
    Map? selectionExtraInfo,
  }) async {
    await updateNode(
      selection,
      (node) => node.copyWith(
        attributes: {
          ...node.attributes,
          blockComponentAlign: alignment,
        },
      ),
      selectionExtraInfo: selectionExtraInfo,
    );
  }

  Future<void> updateTextAndHref(
    String? prevText,
    String? prevHref,
    String? text,
    String? href, {
    Selection? selection,
  }) async {
    if (prevText == null && text == null) {
      return;
    }

    selection ??= this.selection;
    // doesn't support multiple selection now
    if (selection == null || !selection.isSingle) {
      return;
    }

    final node = getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }

    final transaction = this.transaction;

    // insert a new link
    if (prevText == null &&
        text != null &&
        text.isNotEmpty &&
        selection.isCollapsed) {
      final attributes = href != null && href.isNotEmpty
          ? {
              AppFlowyRichTextKeys.href: href,
            }
          : null;
      transaction.insertText(
        node,
        selection.startIndex,
        text,
        attributes: attributes,
      );
    } else if (text != null && prevText != text) {
      // update text
      transaction.replaceText(
        node,
        selection.startIndex,
        selection.length,
        text,
      );
    }

    // if the text is empty, it means the user wants to remove the text
    if (text != null && text.isNotEmpty && prevHref != href) {
      // update href
      transaction.formatText(
        node,
        selection.startIndex,
        text.length,
        {
          AppFlowyRichTextKeys.href: href?.isEmpty == true ? null : href,
        },
      );
    }

    await apply(transaction);
  }
}
