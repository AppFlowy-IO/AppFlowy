import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';

abstract class DefaultSelectableMixinState<T extends StatefulWidget>
    extends State<T> with SelectableMixin {
  final widgetKey = GlobalKey();
  RenderBox? get _renderBox =>
      widgetKey.currentContext?.findRenderObject() as RenderBox?;

  Node get currentNode;

  EdgeInsets get boxPadding => EdgeInsets.zero;

  @override
  Position start() => Position(path: currentNode.path);

  @override
  Position end() => Position(path: currentNode.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    final box = _renderBox;
    if (box is RenderBox) {
      return boxPadding.topLeft & box.size;
    }
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final rects = getRectsInSelection(Selection.collapsed(position));
    return rects.firstOrNull;
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final parentBox = context.findRenderObject();
    final box = widgetKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && box is RenderBox) {
      return [
        box.localToGlobal(Offset.zero, ancestor: parentBox) & box.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: currentNode.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) =>
      _renderBox!.localToGlobal(offset);
}
