import 'dart:async';

import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_edit_link_widget.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_edit_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> onMobileLinkButtonTap(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null) {
    return;
  }
  final nodes = editorState.getNodesInSelection(selection);
  // show edit link bottom sheet
  final context = nodes.firstOrNull?.context;
  if (context != null) {
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
    await showEditLinkBottomSheet(context, selection, editorState);
  }
}

Future<T?> showEditLinkBottomSheet<T>(
  BuildContext context,
  Selection selection,
  EditorState editorState,
) async {
  final currentViewId = context.read<DocumentBloc?>()?.documentId ?? '';
  final text = editorState.getTextInSelection(selection).join();
  final href = editorState.getDeltaAttributeValueInSelection<String>(
    AppFlowyRichTextKeys.href,
    selection,
  );
  final isPage = editorState.getDeltaAttributeValueInSelection<bool>(
    kIsPageLink,
    selection,
  );
  final linkInfo =
      LinkInfo(name: text, link: href ?? '', isPage: isPage ?? false);
  return showMobileBottomSheet(
    context,
    showDragHandle: true,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    builder: (context) {
      return MobileBottomSheetEditLinkWidget(
        currentViewId: currentViewId,
        linkInfo: linkInfo,
        onApply: (info) => LinkUtil.applyLink(editorState, selection, info),
        onRemoveLink: (_) => LinkUtil.removeLink(editorState, selection),
        onDispose: () {
          editorState.service.keyboardService?.closeKeyboard();
        },
      );
    },
  );
}
