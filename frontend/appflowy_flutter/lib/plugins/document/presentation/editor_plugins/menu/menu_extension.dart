import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

extension MenuExtension on EditorState {
  MenuPosition? calculateMenuOffset({
    Rect? rect,
    required double menuWidth,
    required double menuHeight,
    Offset menuOffset = const Offset(0, 10),
  }) {
    final selectionService = service.selectionService;
    final selectionRects = selectionService.selectionRects;
    late Rect startRect;
    if (rect != null) {
      startRect = rect;
    } else {
      if (selectionRects.isEmpty) return null;
      startRect = selectionRects.first;
    }

    final editorOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = renderBox!.size.height;
    final editorWidth = renderBox!.size.width;

    // show below default
    Alignment alignment = Alignment.topLeft;
    final bottomRight = startRect.bottomRight;
    final topRight = startRect.topRight;
    var startOffset = bottomRight + menuOffset;
    Offset offset = Offset(
      startOffset.dx,
      startOffset.dy,
    );

    // show above
    if (startOffset.dy + menuHeight >= editorOffset.dy + editorHeight) {
      startOffset = topRight - menuOffset;
      alignment = Alignment.bottomLeft;

      offset = Offset(
        startOffset.dx,
        editorHeight + editorOffset.dy - startOffset.dy,
      );
    }

    // show on right
    if (offset.dx + menuWidth < editorOffset.dx + editorWidth) {
      offset = Offset(
        offset.dx,
        offset.dy,
      );
    } else if (startOffset.dx - editorOffset.dx > menuWidth) {
      // show on left
      alignment = alignment == Alignment.topLeft
          ? Alignment.topRight
          : Alignment.bottomRight;

      offset = Offset(
        editorWidth - offset.dx + editorOffset.dx,
        offset.dy,
      );
    }
    return MenuPosition(align: alignment, offset: offset);
  }
}

class MenuPosition {
  MenuPosition({
    required this.align,
    required this.offset,
  });

  final Alignment align;
  final Offset offset;

  LTRB get ltrb {
    double? left, top, right, bottom;
    switch (align) {
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

    return LTRB(left: left, top: top, right: right, bottom: bottom);
  }
}

class LTRB {
  LTRB({this.left, this.top, this.right, this.bottom});

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  Positioned buildPositioned({required Widget child}) => Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        child: child,
      );
}
