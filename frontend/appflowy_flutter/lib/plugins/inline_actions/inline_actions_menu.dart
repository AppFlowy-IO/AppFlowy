import 'dart:async';

import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

abstract class InlineActionsMenuService {
  InlineActionsMenuStyle get style;

  Future<void> show();

  void dismiss();
}

class InlineActionsMenu extends InlineActionsMenuService {
  InlineActionsMenu({
    required this.context,
    required this.editorState,
    required this.service,
    required this.initialResults,
    required this.style,
    this.startCharAmount = 1,
    this.cancelBySpaceHandler,
  });

  final BuildContext context;
  final EditorState editorState;
  final InlineActionsService service;
  final List<InlineActionsResult> initialResults;
  final bool Function()? cancelBySpaceHandler;

  @override
  final InlineActionsMenuStyle style;

  final int startCharAmount;

  OverlayEntry? _menuEntry;
  Offset _offset = Offset.zero;
  Alignment _alignment = Alignment.topLeft;
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
  }

  void _onSelectionUpdate() => selectionChangedByMenu = true;

  @override
  Future<void> show() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _show();
      completer.complete();
    });
    return completer.future;
  }

  void _show() {
    dismiss();

    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }

    calculateSelectionMenuOffset(selectionRects.first);
    final (left, top, right, bottom) = _getPosition(_alignment, _offset);

    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;
    _menuEntry = OverlayEntry(
      builder: (context) => SizedBox(
        height: editorHeight,
        width: editorWidth,

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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: InlineActionsHandler(
                    service: service,
                    results: initialResults,
                    editorState: editorState,
                    menuService: this,
                    onDismiss: dismiss,
                    onSelectionUpdate: _onSelectionUpdate,
                    style: style,
                    startCharAmount: startCharAmount,
                    cancelBySpaceHandler: cancelBySpaceHandler,
                  ),
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

  void calculateSelectionMenuOffset(Rect rect) {
    const menuHeight = kInlineMenuHeight, menuWidth = kInlineMenuWidth;
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

class InlineActionsMenuStyle {
  InlineActionsMenuStyle({
    required this.backgroundColor,
    required this.groupTextColor,
    required this.menuItemTextColor,
    required this.menuItemSelectedColor,
    required this.menuItemSelectedTextColor,
  });

  const InlineActionsMenuStyle.light()
      : backgroundColor = Colors.white,
        groupTextColor = const Color(0xFF555555),
        menuItemTextColor = const Color(0xFF333333),
        menuItemSelectedColor = const Color(0xFFE0F8FF),
        menuItemSelectedTextColor = const Color.fromARGB(255, 56, 91, 247);

  const InlineActionsMenuStyle.dark()
      : backgroundColor = const Color(0xFF282E3A),
        groupTextColor = const Color(0xFFBBC3CD),
        menuItemTextColor = const Color(0xFFBBC3CD),
        menuItemSelectedColor = const Color(0xFF00BCF0),
        menuItemSelectedTextColor = const Color(0xFF131720);

  /// The background color of the context menu itself
  ///
  final Color backgroundColor;

  /// The color of the [InlineActionsGroup]'s title text
  ///
  final Color groupTextColor;

  /// The text color of an [InlineActionsMenuItem]
  ///
  final Color menuItemTextColor;

  /// The background of the currently selected [InlineActionsMenuItem]
  ///
  final Color menuItemSelectedColor;

  /// The text color of the currently selected [InlineActionsMenuItem]
  ///
  final Color menuItemSelectedTextColor;
}
