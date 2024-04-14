import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/type_option_menu_item.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/mobile_add_block_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy_code_block/appflowy_code_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final addBlockToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, service, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      icon: FlowySvgs.m_toolbar_add_m,
      onTap: () {
        final selection = editorState.selection;
        service.closeKeyboard();

        // delay to wait the keyboard closed.
        Future.delayed(const Duration(milliseconds: 100), () async {
          unawaited(
            editorState.updateSelectionWithReason(
              selection,
              extraInfo: {
                selectionExtraInfoDisableMobileToolbarKey: true,
                selectionExtraInfoDisableFloatingToolbar: true,
                selectionExtraInfoDoNotAttachTextService: true,
              },
            ),
          );
          keepEditorFocusNotifier.increase();
          final didAddBlock = await showAddBlockMenu(
            AppGlobals.rootNavKey.currentContext!,
            editorState: editorState,
            selection: selection!,
          );
          if (didAddBlock != true) {
            unawaited(
              editorState.updateSelectionWithReason(
                selection,
              ),
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
    showDragHandle: true,
    showCloseButton: true,
    title: LocaleKeys.button_add.tr(),
    barrierColor: Colors.transparent,
    backgroundColor: theme.toolbarMenuBackgroundColor,
    elevation: 20,
    enableDraggableScrollable: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.all(16 * context.scale),
        child: _AddBlockMenu(
          selection: selection,
          editorState: editorState,
        ),
      );
    },
  );
}

class _AddBlockMenu extends StatelessWidget {
  const _AddBlockMenu({
    required this.selection,
    required this.editorState,
  });

  final Selection selection;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return TypeOptionMenu<String>(
      values: buildTypeOptionMenuItemValues(context),
      scaleFactor: context.scale,
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

  List<TypeOptionMenuItemValue<String>> buildTypeOptionMenuItemValues(
    BuildContext context,
  ) {
    final colorMap = _colorMap(context);
    return [
      // heading 1 - 3
      TypeOptionMenuItemValue(
        value: HeadingBlockKeys.type,
        backgroundColor: colorMap[HeadingBlockKeys.type]!,
        text: LocaleKeys.editor_heading1.tr(),
        icon: FlowySvgs.m_add_block_h1_s,
        onTap: (_, __) => _insertBlock(headingNode(level: 1)),
      ),
      TypeOptionMenuItemValue(
        value: HeadingBlockKeys.type,
        backgroundColor: colorMap[HeadingBlockKeys.type]!,
        text: LocaleKeys.editor_heading2.tr(),
        icon: FlowySvgs.m_add_block_h2_s,
        onTap: (_, __) => _insertBlock(headingNode(level: 2)),
      ),
      TypeOptionMenuItemValue(
        value: HeadingBlockKeys.type,
        backgroundColor: colorMap[HeadingBlockKeys.type]!,
        text: LocaleKeys.editor_heading3.tr(),
        icon: FlowySvgs.m_add_block_h3_s,
        onTap: (_, __) => _insertBlock(headingNode(level: 3)),
      ),

      // paragraph
      TypeOptionMenuItemValue(
        value: ParagraphBlockKeys.type,
        backgroundColor: colorMap[ParagraphBlockKeys.type]!,
        text: LocaleKeys.editor_text.tr(),
        icon: FlowySvgs.m_add_block_paragraph_s,
        onTap: (_, __) => _insertBlock(paragraphNode()),
      ),

      // checkbox
      TypeOptionMenuItemValue(
        value: TodoListBlockKeys.type,
        backgroundColor: colorMap[TodoListBlockKeys.type]!,
        text: LocaleKeys.editor_checkbox.tr(),
        icon: FlowySvgs.m_add_block_checkbox_s,
        onTap: (_, __) => _insertBlock(todoListNode(checked: false)),
      ),

      // quote
      TypeOptionMenuItemValue(
        value: QuoteBlockKeys.type,
        backgroundColor: colorMap[QuoteBlockKeys.type]!,
        text: LocaleKeys.editor_quote.tr(),
        icon: FlowySvgs.m_add_block_quote_s,
        onTap: (_, __) => _insertBlock(quoteNode()),
      ),

      // bulleted list, numbered list, toggle list
      TypeOptionMenuItemValue(
        value: BulletedListBlockKeys.type,
        backgroundColor: colorMap[BulletedListBlockKeys.type]!,
        text: LocaleKeys.editor_bulletedListShortForm.tr(),
        icon: FlowySvgs.m_add_block_bulleted_list_s,
        onTap: (_, __) => _insertBlock(bulletedListNode()),
      ),
      TypeOptionMenuItemValue(
        value: NumberedListBlockKeys.type,
        backgroundColor: colorMap[NumberedListBlockKeys.type]!,
        text: LocaleKeys.editor_numberedListShortForm.tr(),
        icon: FlowySvgs.m_add_block_numbered_list_s,
        onTap: (_, __) => _insertBlock(numberedListNode()),
      ),
      TypeOptionMenuItemValue(
        value: ToggleListBlockKeys.type,
        backgroundColor: colorMap[ToggleListBlockKeys.type]!,
        text: LocaleKeys.editor_toggleListShortForm.tr(),
        icon: FlowySvgs.m_add_block_toggle_s,
        onTap: (_, __) => _insertBlock(toggleListBlockNode()),
      ),

      // image
      TypeOptionMenuItemValue(
        value: ImageBlockKeys.type,
        backgroundColor: colorMap[ImageBlockKeys.type]!,
        text: LocaleKeys.editor_image.tr(),
        icon: FlowySvgs.m_add_block_image_s,
        onTap: (_, __) async {
          AppGlobals.rootNavKey.currentContext?.pop(true);
          Future.delayed(const Duration(milliseconds: 400), () async {
            final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
            await editorState.insertEmptyImageBlock(imagePlaceholderKey);
          });
        },
      ),

      // date
      TypeOptionMenuItemValue(
        value: ParagraphBlockKeys.type,
        backgroundColor: colorMap['date']!,
        text: LocaleKeys.editor_date.tr(),
        icon: FlowySvgs.m_add_block_date_s,
        onTap: (_, __) => _insertBlock(dateMentionNode()),
      ),

      // divider
      TypeOptionMenuItemValue(
        value: DividerBlockKeys.type,
        backgroundColor: colorMap[DividerBlockKeys.type]!,
        text: LocaleKeys.editor_divider.tr(),
        icon: FlowySvgs.m_add_block_divider_s,
        onTap: (_, __) {
          AppGlobals.rootNavKey.currentContext?.pop(true);
          Future.delayed(const Duration(milliseconds: 100), () {
            editorState.insertDivider(selection);
          });
        },
      ),

      // callout, code, math equation
      TypeOptionMenuItemValue(
        value: CalloutBlockKeys.type,
        backgroundColor: colorMap[CalloutBlockKeys.type]!,
        text: LocaleKeys.document_plugins_callout.tr(),
        icon: FlowySvgs.m_add_block_callout_s,
        onTap: (_, __) => _insertBlock(calloutNode()),
      ),
      TypeOptionMenuItemValue(
        value: CodeBlockKeys.type,
        backgroundColor: colorMap[CodeBlockKeys.type]!,
        text: LocaleKeys.editor_codeBlockShortForm.tr(),
        icon: FlowySvgs.m_add_block_code_s,
        onTap: (_, __) => _insertBlock(codeBlockNode()),
      ),
      TypeOptionMenuItemValue(
        value: MathEquationBlockKeys.type,
        backgroundColor: colorMap[MathEquationBlockKeys.type]!,
        text: LocaleKeys.editor_mathEquationShortForm.tr(),
        icon: FlowySvgs.m_add_block_formula_s,
        onTap: (_, __) {
          AppGlobals.rootNavKey.currentContext?.pop(true);
          Future.delayed(const Duration(milliseconds: 100), () {
            editorState.insertMathEquation(selection);
          });
        },
      ),
    ];
  }

  Map<String, Color> _colorMap(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return {
        HeadingBlockKeys.type: const Color(0xFF5465A1),
        ParagraphBlockKeys.type: const Color(0xFF5465A1),
        TodoListBlockKeys.type: const Color(0xFF4BB299),
        QuoteBlockKeys.type: const Color(0xFFBAAC74),
        BulletedListBlockKeys.type: const Color(0xFFA35F94),
        NumberedListBlockKeys.type: const Color(0xFFA35F94),
        ToggleListBlockKeys.type: const Color(0xFFA35F94),
        ImageBlockKeys.type: const Color(0xFFBAAC74),
        'date': const Color(0xFF40AAB8),
        DividerBlockKeys.type: const Color(0xFF4BB299),
        CalloutBlockKeys.type: const Color(0xFF66599B),
        CodeBlockKeys.type: const Color(0xFF66599B),
        MathEquationBlockKeys.type: const Color(0xFF66599B),
      };
    }
    return {
      HeadingBlockKeys.type: const Color(0xFFBECCFF),
      ParagraphBlockKeys.type: const Color(0xFFBECCFF),
      TodoListBlockKeys.type: const Color(0xFF98F4CD),
      QuoteBlockKeys.type: const Color(0xFFFDEDA7),
      BulletedListBlockKeys.type: const Color(0xFFFFB9EF),
      NumberedListBlockKeys.type: const Color(0xFFFFB9EF),
      ToggleListBlockKeys.type: const Color(0xFFFFB9EF),
      ImageBlockKeys.type: const Color(0xFFFDEDA7),
      'date': const Color(0xFF91EAF5),
      DividerBlockKeys.type: const Color(0xFF98F4CD),
      CalloutBlockKeys.type: const Color(0xFFCABDFF),
      CodeBlockKeys.type: const Color(0xFFCABDFF),
      MathEquationBlockKeys.type: const Color(0xFFCABDFF),
    };
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
      Position(path: path),
    );
    transaction.selectionExtraInfo = {};
    await apply(transaction);
  }
}
