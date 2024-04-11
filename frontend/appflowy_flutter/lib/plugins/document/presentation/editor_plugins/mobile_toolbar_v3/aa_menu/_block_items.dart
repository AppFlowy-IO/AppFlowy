import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/utils.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_menu_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_popup_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BlockItems extends StatelessWidget {
  BlockItems({
    super.key,
    required this.service,
    required this.editorState,
  });

  final EditorState editorState;
  final AppFlowyMobileToolbarWidgetService service;

  final List<(FlowySvgData, String)> _blockItems = [
    (FlowySvgs.m_toolbar_bulleted_list_m, BulletedListBlockKeys.type),
    (FlowySvgs.m_toolbar_numbered_list_m, NumberedListBlockKeys.type),
    (FlowySvgs.m_aa_quote_m, QuoteBlockKeys.type),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._blockItems
              .mapIndexed(
                (index, e) => [
                  _buildBlockItem(
                    context,
                    index,
                    e.$1,
                    e.$2,
                  ),
                  if (index != 0) const ScaledVerticalDivider(),
                ],
              )
              .flattened,
          // this item is a special case, use link item here instead of block item
          _buildLinkItem(context),
        ],
      ),
    );
  }

  Widget _buildBlockItem(
    BuildContext context,
    int index,
    FlowySvgData icon,
    String blockType,
  ) {
    final theme = ToolbarColorExtension.of(context);
    return MobileToolbarMenuItemWrapper(
      size: const Size(62, 54),
      enableTopLeftRadius: index == 0,
      enableBottomLeftRadius: index == 0,
      enableTopRightRadius: false,
      enableBottomRightRadius: false,
      onTap: () async {
        await _convert(blockType);
      },
      backgroundColor: theme.toolbarMenuItemBackgroundColor,
      icon: icon,
      isSelected: editorState.isBlockTypeSelected(blockType),
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    final items = [
      (AppFlowyRichTextKeys.code, FlowySvgs.m_aa_code_m),
      // (InlineMathEquationKeys.formula, FlowySvgs.m_aa_math_s),
    ];
    return PopupMenu(
      itemLength: items.length,
      onSelected: (index) async {
        await editorState.toggleAttribute(items[index].$1);
      },
      menuBuilder: (context, keys, currentIndex) {
        final children = items
            .mapIndexed(
              (index, e) => [
                PopupMenuItemWrapper(
                  key: keys[index],
                  isSelected: currentIndex == index,
                  icon: e.$2,
                ),
                if (index != 0 || index != items.length - 1) const HSpace(12),
              ],
            )
            .flattened
            .toList();
        return PopupMenuWrapper(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
      builder: (context, key) => MobileToolbarMenuItemWrapper(
        key: key,
        size: const Size(62, 54),
        enableTopLeftRadius: false,
        enableBottomLeftRadius: false,
        showDownArrow: true,
        onTap: _onLinkItemTap,
        backgroundColor: theme.toolbarMenuItemBackgroundColor,
        icon: FlowySvgs.m_toolbar_link_m,
        isSelected: false,
        iconPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
        ),
      ),
    );
  }

  void _onLinkItemTap() async {
    final selection = editorState.selection;
    if (selection == null) {
      return;
    }
    final nodes = editorState.getNodesInSelection(selection);
    // show edit link bottom sheet
    final context = nodes.firstOrNull?.context;
    if (context != null) {
      _closeKeyboard(selection);

      // keep the selection
      unawaited(
        editorState.updateSelectionWithReason(
          selection,
          extraInfo: {
            selectionExtraInfoDisableMobileToolbarKey: true,
            selectionExtraInfoDoNotAttachTextService: true,
            selectionExtraInfoDisableFloatingToolbar: true,
          },
        ),
      );
      keepEditorFocusNotifier.increase();

      final text = editorState
          .getTextInSelection(
            selection,
          )
          .join();
      final href = editorState.getDeltaAttributeValueInSelection<String>(
        AppFlowyRichTextKeys.href,
        selection,
      );
      await showEditLinkBottomSheet(
        context,
        text,
        href,
        (context, newText, newHref) {
          editorState.updateTextAndHref(
            text,
            href,
            newText,
            newHref,
            selection: selection,
          );
          context.pop(true);
        },
      );
      // re-open the keyboard again
      unawaited(
        editorState.updateSelectionWithReason(
          selection,
          extraInfo: {},
        ),
      );
    }
  }

  void _closeKeyboard(Selection selection) {
    editorState.updateSelectionWithReason(
      selection,
      extraInfo: {
        selectionExtraInfoDisableMobileToolbarKey: true,
        selectionExtraInfoDoNotAttachTextService: true,
      },
    );
    editorState.service.keyboardService?.closeKeyboard();
  }

  Future<void> _convert(String blockType) async {
    await editorState.convertBlockType(
      blockType,
      selectionExtraInfo: {
        selectionExtraInfoDoNotAttachTextService: true,
        selectionExtraInfoDisableFloatingToolbar: true,
      },
    );
    unawaited(
      editorState.updateSelectionWithReason(
        editorState.selection,
        extraInfo: {
          selectionExtraInfoDisableFloatingToolbar: true,
          selectionExtraInfoDoNotAttachTextService: true,
        },
      ),
    );
  }
}
