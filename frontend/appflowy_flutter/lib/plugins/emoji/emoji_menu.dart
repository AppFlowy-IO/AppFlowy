import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'emoji_actions_command.dart';
import 'emoji_handler.dart';

abstract class EmojiMenuService {
  void show();

  void dismiss();
}

class EmojiMenu extends EmojiMenuService {
  EmojiMenu({
    required this.context,
    required this.editorState,
    this.startCharAmount = 1,
    this.cancelBySpaceHandler,
    this.menuHeight = 400,
    this.menuWidth = 300,
  });

  final BuildContext context;
  final EditorState editorState;
  final double menuHeight;
  final double menuWidth;
  final bool Function()? cancelBySpaceHandler;

  final int startCharAmount;
  Offset _offset = Offset.zero;
  Alignment _alignment = Alignment.topLeft;
  OverlayEntry? _menuEntry;
  bool selectionChangedByMenu = false;

  @override
  void dismiss() {
    if (_menuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
      keepEditorFocusNotifier.decrease();
    }

    _menuEntry?.remove();
    _menuEntry = null;

    // workaround: SelectionService has been released after hot reload.
    final isSelectionDisposed =
        editorState.service.selectionServiceKey.currentState == null;
    if (!isSelectionDisposed) {
      final selectionService = editorState.service.selectionService;
      selectionService.currentSelection.removeListener(_onSelectionChange);
    }
    emojiMenuService = null;
  }

  void _onSelectionUpdate() => selectionChangedByMenu = true;

  @override
  void show() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }

    final Size editorSize = editorState.renderBox!.size;

    calculateSelectionMenuOffset(selectionRects.first);

    final (left, top, right, bottom) = _getPosition();

    _menuEntry = OverlayEntry(
      builder: (context) => SizedBox(
        height: editorSize.height,
        width: editorSize.width,

        // GestureDetector handles clicks outside of the context menu,
        // to dismiss the context menu.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dismiss,
          child: Stack(
            children: [
              Positioned(
                top: top,
                bottom: bottom,
                left: left,
                right: right,
                child: EmojiHandler(
                  editorState: editorState,
                  menuService: this,
                  onDismiss: dismiss,
                  onSelectionUpdate: _onSelectionUpdate,
                  startCharAmount: startCharAmount,
                  cancelBySpaceHandler: cancelBySpaceHandler,
                  onEmojiSelect: (
                    BuildContext context,
                    (int, int) replacement,
                    String emoji,
                  ) async {
                    final selection = editorState.selection;

                    if (selection == null) return;
                    final node =
                        editorState.document.nodeAtPath(selection.end.path);
                    if (node == null) return;
                    final transaction = editorState.transaction
                      ..replaceText(
                        node,
                        replacement.$1,
                        replacement.$2,
                        emoji,
                      );
                    await editorState.apply(transaction);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuEntry!);

    editorState.service.keyboardService?.disable(showCursor: true);
    editorState.service.scrollService?.disable();
    selectionService.currentSelection.addListener(_onSelectionChange);
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

    if (!selectionChangedByMenu) {
      return dismiss();
    }

    selectionChangedByMenu = false;
  }

  (double? left, double? top, double? right, double? bottom) _getPosition() {
    double? left, top, right, bottom;
    switch (_alignment) {
      case Alignment.topLeft:
        left = _offset.dx;
        top = _offset.dy;
        break;
      case Alignment.bottomLeft:
        left = _offset.dx;
        bottom = _offset.dy;
        break;
      case Alignment.topRight:
        right = _offset.dx;
        top = _offset.dy;
        break;
      case Alignment.bottomRight:
        right = _offset.dx;
        bottom = _offset.dy;
        break;
    }

    return (left, top, right, bottom);
  }

  void calculateSelectionMenuOffset(Rect rect) {
    // Workaround: We can customize the padding through the [EditorStyle],
    // but the coordinates of overlay are not properly converted currently.
    // Just subtract the padding here as a result.
    const menuOffset = Offset(0, 10);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;

    // show below default
    _alignment = Alignment.topLeft;
    final bottomRight = rect.bottomRight;
    final topRight = rect.topRight;
    var offset = bottomRight + menuOffset;
    _offset = Offset(
      offset.dx,
      offset.dy,
    );

    // show above
    if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
      offset = topRight - menuOffset;
      _alignment = Alignment.bottomLeft;

      _offset = Offset(
        offset.dx,
        editorHeight + editorOffset.dy - offset.dy,
      );
    }

    // show on right
    if (_offset.dx + menuWidth < editorOffset.dx + editorWidth) {
      _offset = Offset(
        _offset.dx,
        _offset.dy,
      );
    } else if (offset.dx - editorOffset.dx > menuWidth) {
      // show on left
      _alignment = _alignment == Alignment.topLeft
          ? Alignment.topRight
          : Alignment.bottomRight;

      _offset = Offset(
        editorWidth - _offset.dx + editorOffset.dx,
        _offset.dy,
      );
    }
  }
}
