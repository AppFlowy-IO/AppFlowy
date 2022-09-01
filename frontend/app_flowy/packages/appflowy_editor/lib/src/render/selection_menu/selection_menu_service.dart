import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/image/image_upload_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_widget.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:flutter/material.dart';

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
    final offset = selectionRects.first.bottomRight + const Offset(10, 10);
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
    name: 'Text',
    icon: _selectionMenuIcon('text'),
    keywords: ['text'],
    handler: (editorState, _, __) {
      insertTextNodeAfterSelection(editorState, {});
    },
  ),
  SelectionMenuItem(
    name: 'Heading 1',
    icon: _selectionMenuIcon('h1'),
    keywords: ['heading 1, h1'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, StyleKey.h1);
    },
  ),
  SelectionMenuItem(
    name: 'Heading 2',
    icon: _selectionMenuIcon('h2'),
    keywords: ['heading 2, h2'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, StyleKey.h2);
    },
  ),
  SelectionMenuItem(
    name: 'Heading 3',
    icon: _selectionMenuIcon('h3'),
    keywords: ['heading 3, h3'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, StyleKey.h3);
    },
  ),
  SelectionMenuItem(
    name: 'Image',
    icon: _selectionMenuIcon('image'),
    keywords: ['image'],
    handler: showImageUploadMenu,
  ),
  SelectionMenuItem(
    name: 'Bulleted list',
    icon: _selectionMenuIcon('bulleted_list'),
    keywords: ['bulleted list', 'list', 'unordered list'],
    handler: (editorState, _, __) {
      insertBulletedListAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: 'Checkbox',
    icon: _selectionMenuIcon('checkbox'),
    keywords: ['todo list', 'list', 'checkbox list'],
    handler: (editorState, _, __) {
      insertCheckboxAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: 'Quote',
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
