import 'dart:async';

import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'mobile_inline_actions_handler.dart';

class MobileInlineActionsMenu extends InlineActionsMenuService {
  MobileInlineActionsMenu({
    required this.context,
    required this.editorState,
    required this.initialResults,
    required this.style,
    required this.service,
    this.startCharAmount = 1,
    this.cancelBySpaceHandler,
  });

  final BuildContext context;
  final EditorState editorState;
  final List<InlineActionsResult> initialResults;
  final bool Function()? cancelBySpaceHandler;
  final InlineActionsService service;

  @override
  final InlineActionsMenuStyle style;

  final int startCharAmount;

  OverlayEntry? _menuEntry;

  @override
  void dismiss() {
    if (_menuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
    }

    _menuEntry?.remove();
    _menuEntry = null;
  }

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
    final selectionRects = editorState.selectionRects();
    if (selectionRects.isEmpty) {
      return;
    }

    const double menuHeight = 192.0;
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

    final (left, top, right, bottom) = _getPosition(alignment, offset);

    _menuEntry = OverlayEntry(
      builder: (context) => SizedBox(
        width: editorSize.width,
        height: editorSize.height,
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
                child: MobileInlineActionsHandler(
                  service: service,
                  results: initialResults,
                  editorState: editorState,
                  menuService: this,
                  onDismiss: dismiss,
                  style: style,
                  startCharAmount: startCharAmount,
                  cancelBySpaceHandler: cancelBySpaceHandler,
                  startOffset: editorState.selection?.start.offset ?? 0,
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
  }

  (double? left, double? top, double? right, double? bottom) _getPosition(
    Alignment alignment,
    Offset offset,
  ) {
    double? left, top, right, bottom;
    switch (alignment) {
      case Alignment.topLeft:
        left = 0;
        top = offset.dy;
        break;
      case Alignment.bottomLeft:
        left = 0;
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
