import 'package:flutter/material.dart';

import '../../core/legacy/built_in_attribute_keys.dart';
import '../../editor_state.dart';
import '../../infra/flowy_svg.dart';
import '../../l10n/l10n.dart';
import '../../service/default_text_operations/format_rich_text_style.dart';
import '../image/image_upload_widget.dart';
import 'selection_menu_widget.dart';

abstract class SelectionMenuService {
  Offset get topLeft;
  Offset get offset;
  Alignment get alignment;

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
  Offset _offset = Offset.zero;
  Alignment _alignment = Alignment.topLeft;

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
    const menuHeight = 200.0;
    const menuOffset = Offset(0, 10);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = editorState.renderBox!.size.height;

    // show below defualt
    var showBelow = true;
    _alignment = Alignment.bottomLeft;
    final bottomRight = selectionRects.first.bottomRight;
    final topRight = selectionRects.first.topRight;
    var offset = bottomRight + menuOffset;
    // overflow
    if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
      // show above
      offset = topRight - menuOffset;
      showBelow = false;
      _alignment = Alignment.topRight;
    }
    _topLeft = offset;
    _offset = Offset(offset.dx, showBelow ? offset.dy : MediaQuery.of(context).size.height - offset.dy);

    _selectionMenuEntry = OverlayEntry(builder: (context) {
      return Positioned(
        top: showBelow ? _offset.dy : null,
        bottom:
            showBelow ? null : _offset.dy,
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

  @override
  Alignment get alignment {
    return _alignment;
  }

  @override
  Offset get offset {
    return _offset;
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
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('text', editorState, onSelected),
    keywords: ['text'],
    handler: (editorState, _, __) {
      insertTextNodeAfterSelection(editorState, {});
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.heading1,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('h1', editorState, onSelected),
    keywords: ['heading 1, h1'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h1);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.heading2,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('h2', editorState, onSelected),
    keywords: ['heading 2, h2'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h2);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.heading3,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('h3', editorState, onSelected),
    keywords: ['heading 3, h3'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h3);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.image,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('image', editorState, onSelected),
    keywords: ['image'],
    handler: showImageUploadMenu,
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.bulletedList,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('bulleted_list', editorState, onSelected),
    keywords: ['bulleted list', 'list', 'unordered list'],
    handler: (editorState, _, __) {
      insertBulletedListAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.numberedList,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('number', editorState, onSelected),
    keywords: ['numbered list', 'list', 'ordered list'],
    handler: (editorState, _, __) {
      insertNumberedListAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.checkbox,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('checkbox', editorState, onSelected),
    keywords: ['todo list', 'list', 'checkbox list'],
    handler: (editorState, _, __) {
      insertCheckboxAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: () => AppFlowyEditorLocalizations.current.quote,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('quote', editorState, onSelected),
    keywords: ['quote', 'refer'],
    handler: (editorState, _, __) {
      insertQuoteAfterSelection(editorState);
    },
  ),
];

Widget _selectionMenuIcon(
    String name, EditorState editorState, bool onSelected) {
  return FlowySvg(
    name: 'selection_menu/$name',
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    width: 18.0,
    height: 18.0,
  );
}
