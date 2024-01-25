import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/mobile_add_block_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:go_router/go_router.dart';

final addBlockToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, service, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      icon: FlowySvgs.m_toolbar_add_s,
      onTap: () {
        final selection = editorState.selection;
        service.closeKeyboard();

        // delay to wait the keyboard closed.
        Future.delayed(const Duration(milliseconds: 100), () async {
          editorState.updateSelectionWithReason(
            selection,
            extraInfo: {
              selectionExtraInfoDisableMobileToolbarKey: true,
              selectionExtraInfoDisableFloatingToolbar: true,
              selectionExtraInfoDoNotAttachTextService: true,
            },
          );
          keepEditorFocusNotifier.increase();
          final didAddBlock = await showAddBlockMenu(
            AppGlobals.rootNavKey.currentContext!,
            editorState: editorState,
            selection: selection!,
          );
          if (didAddBlock != true) {
            editorState.updateSelectionWithReason(
              selection,
            );
          }
        });
      },
    );
  },
);

Future<bool?> showAddBlockMenu(
  BuildContext context, {
  required EditorState editorState,
  required Selection selection,
}) async {
  final theme = ToolbarColorExtension.of(context);
  return showMobileBottomSheet<bool>(
    context,
    showHeader: true,
    showCloseButton: true,
    showDivider: false,
    showDragHandle: true,
    barrierColor: Colors.transparent,
    backgroundColor: theme.toolbarMenuBackgroundColor,
    elevation: 20,
    title: LocaleKeys.button_add.tr(),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 16),
        child: _AddBlockMenu(
          selection: selection,
          editorState: editorState,
        ),
      );
    },
  );
}

class _AddBlockMenu extends StatelessWidget {
  _AddBlockMenu({
    required this.selection,
    required this.editorState,
  });

  final Selection selection;
  final EditorState editorState;

  late final _menuItemData = [
    // paragraph
    _AddBlockMenuItemData(
      blockType: ParagraphBlockKeys.type,
      backgroundColor: const Color(0xFFBAC9FF),
      text: LocaleKeys.editor_text.tr(),
      icon: FlowySvgs.m_add_block_paragraph_s,
      onTap: () => _insertBlock(paragraphNode()),
    ),

    // heading 1 - 3
    _AddBlockMenuItemData(
      blockType: HeadingBlockKeys.type,
      backgroundColor: const Color(0xFFBAC9FF),
      text: LocaleKeys.editor_heading1.tr(),
      icon: FlowySvgs.m_add_block_h1_s,
      onTap: () => _insertBlock(headingNode(level: 1)),
    ),
    _AddBlockMenuItemData(
      blockType: HeadingBlockKeys.type,
      backgroundColor: const Color(0xFFBAC9FF),
      text: LocaleKeys.editor_heading2.tr(),
      icon: FlowySvgs.m_add_block_h2_s,
      onTap: () => _insertBlock(headingNode(level: 2)),
    ),
    _AddBlockMenuItemData(
      blockType: HeadingBlockKeys.type,
      backgroundColor: const Color(0xFFBAC9FF),
      text: LocaleKeys.editor_heading3.tr(),
      icon: FlowySvgs.m_add_block_h3_s,
      onTap: () => _insertBlock(headingNode(level: 3)),
    ),

    // checkbox
    _AddBlockMenuItemData(
      blockType: TodoListBlockKeys.type,
      backgroundColor: const Color(0xFF91EAF5),
      text: LocaleKeys.editor_checkbox.tr(),
      icon: FlowySvgs.m_add_block_checkbox_s,
      onTap: () => _insertBlock(todoListNode(checked: false)),
    ),

    // list: bulleted, numbered, toggle
    _AddBlockMenuItemData(
      blockType: BulletedListBlockKeys.type,
      backgroundColor: const Color(0xFFFFB9EF),
      text: LocaleKeys.editor_bulletedList.tr(),
      icon: FlowySvgs.m_add_block_bulleted_list_s,
      onTap: () => _insertBlock(bulletedListNode()),
    ),
    _AddBlockMenuItemData(
      blockType: NumberedListBlockKeys.type,
      backgroundColor: const Color(0xFFFFB9EF),
      text: LocaleKeys.editor_numberedList.tr(),
      icon: FlowySvgs.m_add_block_numbered_list_s,
      onTap: () => _insertBlock(numberedListNode()),
    ),
    _AddBlockMenuItemData(
      blockType: ToggleListBlockKeys.type,
      backgroundColor: const Color(0xFFFFB9EF),
      text: LocaleKeys.document_plugins_toggleList.tr(),
      icon: FlowySvgs.m_add_block_toggle_s,
      onTap: () => _insertBlock(toggleListBlockNode()),
    ),

    // callout, code, math equation, quote
    _AddBlockMenuItemData(
      blockType: CalloutBlockKeys.type,
      backgroundColor: const Color(0xFFCABDFF),
      text: LocaleKeys.document_plugins_callout.tr(),
      icon: FlowySvgs.m_add_block_callout_s,
      onTap: () => _insertBlock(calloutNode()),
    ),
    _AddBlockMenuItemData(
      blockType: CodeBlockKeys.type,
      backgroundColor: const Color(0xFFCABDFF),
      text: LocaleKeys.document_selectionMenu_codeBlock.tr(),
      icon: FlowySvgs.m_add_block_code_s,
      onTap: () => _insertBlock(codeBlockNode()),
    ),
    _AddBlockMenuItemData(
      blockType: MathEquationBlockKeys.type,
      backgroundColor: const Color(0xFFCABDFF),
      text: LocaleKeys.document_plugins_mathEquation_name.tr(),
      icon: FlowySvgs.m_add_block_formula_s,
      onTap: () {
        AppGlobals.rootNavKey.currentContext?.pop(true);
        Future.delayed(const Duration(milliseconds: 100), () {
          editorState.insertMathEquation(selection);
        });
      },
    ),
    _AddBlockMenuItemData(
      blockType: QuoteBlockKeys.type,
      backgroundColor: const Color(0xFFFDEDA7),
      text: LocaleKeys.editor_quote.tr(),
      icon: FlowySvgs.m_add_block_quote_s,
      onTap: () => _insertBlock(quoteNode()),
    ),

    // divider
    _AddBlockMenuItemData(
      blockType: DividerBlockKeys.type,
      backgroundColor: const Color(0xFF98F4CD),
      text: LocaleKeys.editor_divider.tr(),
      icon: FlowySvgs.m_add_block_divider_s,
      onTap: () {
        AppGlobals.rootNavKey.currentContext?.pop(true);
        Future.delayed(const Duration(milliseconds: 100), () {
          editorState.insertDivider(selection);
        });
      },
    ),

    // image
    _AddBlockMenuItemData(
      blockType: DividerBlockKeys.type,
      backgroundColor: const Color(0xFF98F4CD),
      text: LocaleKeys.editor_image.tr(),
      icon: FlowySvgs.m_toolbar_imae_lg,
      onTap: () async {
        AppGlobals.rootNavKey.currentContext?.pop(true);
        Future.delayed(const Duration(milliseconds: 400), () async {
          final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
          await editorState.insertEmptyImageBlock(imagePlaceholderKey);
        });
      },
    ),

    // date
    _AddBlockMenuItemData(
      blockType: ParagraphBlockKeys.type,
      backgroundColor: const Color(0xFFF49898),
      text: LocaleKeys.editor_date.tr(),
      icon: FlowySvgs.date_s,
      onTap: () => _insertBlock(dateMentionNode()),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _GridView(
      mainAxisSpacing: 20 * context.scale,
      itemWidth: 68.0 * context.scale,
      crossAxisCount: 4,
      children: _menuItemData.map((e) => _AddBlockMenuItem(data: e)).toList(),
    );
  }

  Future<void> _insertBlock(Node node) async {
    AppGlobals.rootNavKey.currentContext?.pop(true);
    Future.delayed(const Duration(milliseconds: 100), () {
      editorState.insertBlockAfterCurrentSelection(
        selection,
        node,
      );
    });
  }
}

class _AddBlockMenuItemData {
  const _AddBlockMenuItemData({
    required this.blockType,
    required this.backgroundColor,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String blockType;
  final Color backgroundColor;
  final String text;
  final FlowySvgData icon;
  final VoidCallback onTap;
}

class _AddBlockMenuItem extends StatelessWidget {
  const _AddBlockMenuItem({
    required this.data,
  });

  final _AddBlockMenuItemData data;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Column(
        children: [
          Container(
            height: 68.0 * context.scale,
            width: 68.0 * context.scale,
            decoration: ShapeDecoration(
              color: data.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            padding: EdgeInsets.all(20 * context.scale),
            child: FlowySvg(
              data.icon,
              color: Colors.black,
            ),
          ),
          const VSpace(4),
          FlowyText(
            data.text,
            fontSize: 12.0,
          ),
        ],
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  const _GridView({
    required this.children,
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.itemWidth,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i += crossAxisCount)
          Padding(
            padding: EdgeInsets.only(bottom: mainAxisSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var j = 0; j < crossAxisCount; j++)
                  i + j < children.length ? children[i + j] : HSpace(itemWidth),
              ],
            ),
          ),
      ],
    );
  }
}

extension on EditorState {
  Future<void> insertBlockAfterCurrentSelection(
    Selection selection,
    Node node,
  ) async {
    final path = selection.end.path.next;
    final transaction = this.transaction;
    transaction.insertNode(
      path,
      node,
    );
    transaction.afterSelection = Selection.collapsed(
      Position(path: path, offset: 0),
    );
    transaction.selectionExtraInfo = {};
    await apply(transaction);
  }
}
