import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/type_option_menu_item.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'add_block_menu_item_builder.dart';

@visibleForTesting
const addBlockToolbarItemKey = ValueKey('add_block_toolbar_item');

final addBlockToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, service, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      key: addBlockToolbarItemKey,
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
            unawaited(editorState.updateSelectionWithReason(selection));
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
}) async =>
    showMobileBottomSheet<bool>(
      context,
      showHeader: true,
      showDragHandle: true,
      showCloseButton: true,
      title: LocaleKeys.button_add.tr(),
      barrierColor: Colors.transparent,
      backgroundColor:
          ToolbarColorExtension.of(context).toolbarMenuBackgroundColor,
      elevation: 20,
      enableDraggableScrollable: true,
      builder: (_) => Padding(
        padding: EdgeInsets.all(16 * context.scale),
        child: AddBlockMenu(selection: selection, editorState: editorState),
      ),
    );

class AddBlockMenu extends StatelessWidget {
  const AddBlockMenu({
    super.key,
    required this.selection,
    required this.editorState,
  });

  final Selection selection;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final builder = AddBlockMenuItemBuilder(
      editorState: editorState,
      selection: selection,
    );
    return TypeOptionMenu<String>(
      values: builder.buildTypeOptionMenuItemValues(context),
      scaleFactor: context.scale,
    );
  }
}
