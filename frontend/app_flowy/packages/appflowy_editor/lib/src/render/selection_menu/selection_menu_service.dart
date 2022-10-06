import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/l10n/l10n.dart';
import 'package:appflowy_editor/src/render/image/image_upload_widget.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_widget.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';

import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';

abstract class SelectionMenuService {
  Offset get topLeft;

  void show();
  void dismiss();
}

class SelectionMenu implements SelectionMenuService {
  SelectionMenu({
    required this.context,
    required this.editorState,
  });

  final BuildContext context;
  final EditorState editorState;

  OverlayEntry? _selectionMenuEntry;
  bool _selectionUpdateByInner = false;
  Offset? _topLeft;

  @override
  void dismiss() {
    if (_selectionMenuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
    }

    _selectionMenuEntry?.remove();
    _selectionMenuEntry = null;

    // workaround: SelectionService has been released after hot reload.
    final isSelectionDisposed =
        editorState.service.selectionServiceKey.currentState == null;
    if (!isSelectionDisposed) {
      final selectionService = editorState.service.selectionService;
      selectionService.currentSelection.removeListener(_onSelectionChange);
    }
  }

  @override
  void show() {
    dismiss();

    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }
    // Workaround: We can customize the padding through the [EditorStyle],
    //  but the coordinates of overlay are not properly converted currently.
    //  Just subtract the padding here as a result.
    final baseOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final offset =
        selectionRects.first.bottomRight + const Offset(10, 10) - baseOffset;
    _topLeft = offset;

    _selectionMenuEntry = OverlayEntry(builder: (context) {
      return Positioned(
        top: offset.dy,
        left: offset.dx,
        child: SelectionMenuWidget(
          items: [
            ..._defaultSelectionMenuItems,
            ...editorState.selectionMenuItems,
          ],
          maxItemInRow: 5,
          editorState: editorState,
          menuService: this,
          onExit: () {
            dismiss();
          },
          onSelectionUpdate: () {
            _selectionUpdateByInner = true;
          },
        ),
      );
    });

    Overlay.of(context)?.insert(_selectionMenuEntry!);

    editorState.service.keyboardService?.disable();
    editorState.service.scrollService?.disable();
    selectionService.currentSelection.addListener(_onSelectionChange);
  }

  @override
  Offset get topLeft {
    return _topLeft ?? Offset.zero;
  }

  void _onSelectionChange() {
    // workaround: SelectionService has been released after hot reload.
    final isSelectionDisposed =
        editorState.service.selectionServiceKey.currentState == null;
    if (!isSelectionDisposed) {
      final selectionService = editorState.service.selectionService;
      if (selectionService.currentSelection.value == null) {
        return;
      }
    }

    if (_selectionUpdateByInner) {
      _selectionUpdateByInner = false;
      return;
    }

    dismiss();
  }
}

@visibleForTesting
List<SelectionMenuItem> get defaultSelectionMenuItems =>
    _defaultSelectionMenuItems;
final List<SelectionMenuItem> _defaultSelectionMenuItems = [
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.text,
    icon: _selectionMenuIcon('text'),
    keywords: ['text'],
    handler: (editorState, _, __) {
      insertTextNodeAfterSelection(editorState, {});
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.heading1,
    icon: _selectionMenuIcon('h1'),
    keywords: ['heading 1, h1'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h1);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.heading2,
    icon: _selectionMenuIcon('h2'),
    keywords: ['heading 2, h2'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h2);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.heading3,
    icon: _selectionMenuIcon('h3'),
    keywords: ['heading 3, h3'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h3);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.image,
    icon: _selectionMenuIcon('image'),
    keywords: ['image'],
    handler: showImageUploadMenu,
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.bulletedList,
    icon: _selectionMenuIcon('bulleted_list'),
    keywords: ['bulleted list', 'list', 'unordered list'],
    handler: (editorState, _, __) {
      insertBulletedListAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.numberedList,
    icon: _selectionMenuIcon('number'),
    keywords: ['numbered list', 'list', 'ordered list'],
    handler: (editorState, _, __) {
      insertNumberedListAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.checkbox,
    icon: _selectionMenuIcon('checkbox'),
    keywords: ['todo list', 'list', 'checkbox list'],
    handler: (editorState, _, __) {
      insertCheckboxAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.quote,
    icon: _selectionMenuIcon('quote'),
    keywords: ['quote', 'refer'],
    handler: (editorState, _, __) {
      insertQuoteAfterSelection(editorState);
    },
  ),
];

Widget _selectionMenuIcon(String name) {
  return FlowySvg(
    name: 'selection_menu/$name',
    color: Colors.black,
    width: 18.0,
    height: 18.0,
  );
}
