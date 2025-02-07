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
  });

  final BuildContext context;
  final EditorState editorState;
  final bool Function()? cancelBySpaceHandler;

  final int startCharAmount;

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

    const double menuHeight = 200.0;
    const double menuWidth = 150.0;
    const Offset menuOffset = Offset(0, 10);
    final Offset editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size editorSize = editorState.renderBox!.size;
    // Default to opening the overlay below
    Alignment alignment = Alignment.topLeft;

    final firstRect = selectionRects.first;
    Offset offset = firstRect.bottomRight + menuOffset;

    // Show above
    if (offset.dy + menuHeight >= editorOffset.dy + editorSize.height) {
      offset = firstRect.topRight - menuOffset;
      alignment = Alignment.bottomLeft;

      offset = Offset(
        offset.dx,
        MediaQuery.of(context).size.height - offset.dy,
      );
    }

    // Show on the left
    final windowWidth = MediaQuery.of(context).size.width;
    if (offset.dx > (windowWidth - menuWidth)) {
      alignment = alignment == Alignment.topLeft
          ? Alignment.topRight
          : Alignment.bottomRight;

      offset = Offset(
        windowWidth - offset.dx,
        offset.dy,
      );
    }

    final (left, top, right, bottom) = _getPosition(alignment, offset);

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

  (double? left, double? top, double? right, double? bottom) _getPosition(
    Alignment alignment,
    Offset offset,
  ) {
    double? left, top, right, bottom;
    switch (alignment) {
      case Alignment.topLeft:
        left = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomLeft:
        left = offset.dx;
        bottom = offset.dy;
        break;
      case Alignment.topRight:
        right = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomRight:
        right = offset.dx;
        bottom = offset.dy;
        break;
    }

    return (left, top, right, bottom);
  }
}
