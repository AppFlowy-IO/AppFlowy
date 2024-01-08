import 'package:flutter/material.dart';

import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

abstract class InlineActionsMenuService {
  InlineActionsMenuStyle get style;

  void show();
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
  });

  final BuildContext context;
  final EditorState editorState;
  final InlineActionsService service;
  final List<InlineActionsResult> initialResults;

  @override
  final InlineActionsMenuStyle style;

  final int startCharAmount;

  OverlayEntry? _menuEntry;
  bool selectionChangedByMenu = false;

  @override
  void dismiss() {
    if (_menuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
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
  void show() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _show() {
    dismiss();

    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }

    const double menuHeight = 300.0;
    const double menuWidth = 200.0;
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
