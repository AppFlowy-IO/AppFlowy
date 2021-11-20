import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../model/document/node/line.dart';
import '../model/document/node/container.dart' as container_node;
import '../service/cursor.dart';
import '../widget/selection.dart';
import '../widget/text_line.dart';
import 'box.dart';

enum TextLineSlot {
  LEADING,
  BODY,
}

/* ------------------------------- Render Box ------------------------------- */

class RenderEditableTextLine extends RenderEditableBox {
  RenderEditableTextLine(
    this._line,
    this._textDirection,
    this._textSelection,
    this._enableInteractiveSelection,
    this.hasFocus,
    this._devicePixelRatio,
    this._padding,
    this._color,
    this._cursorController,
  );

  RenderBox? _leading;
  RenderContentProxyBox? _body;
  Line _line;
  TextDirection _textDirection;
  TextSelection _textSelection;
  Color _color;
  bool _enableInteractiveSelection;
  bool hasFocus = false;
  double _devicePixelRatio;
  EdgeInsetsGeometry _padding;
  CursorController _cursorController;
  EdgeInsets? _resolvedPadding;
  bool? _containesCursor;
  List<TextBox>? _selectedRects;
  Rect? _caretPrototype;
  final Map<TextLineSlot, RenderBox> children = {};

  // Getter && Setter

  Iterable<RenderBox> get _children sync* {
    if (_leading != null) {
      yield _leading!;
    }
    if (_body != null) {
      yield _body!;
    }
  }

  CursorController get cursorController => _cursorController;

  set cursorController(CursorController value) {
    if (_cursorController == value) {
      return;
    }
    _cursorController = value;
    markNeedsLayout();
  }

  double get devicePixelRatio => _devicePixelRatio;

  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  bool get enableInteractiveSelection => _enableInteractiveSelection;

  set enableInteractiveSelection(bool value) {
    if (_enableInteractiveSelection == value) {
      return;
    }
    _enableInteractiveSelection = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  Color get color => _color;

  set color(Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    if (containsTextSelection()) {
      markNeedsPaint();
    }
  }

  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _resolvedPadding = null;
    markNeedsLayout();
  }

  TextSelection get textSelection => _textSelection;

  set textSelection(TextSelection value) {
    if (_textSelection == value) {
      return;
    }
    final containsSelection = containsTextSelection();
    if (attached && containsCursor()) {
      cursorController.removeListener(markNeedsLayout);
      cursorController.color.removeListener(markNeedsPaint);
    }

    _textSelection = value;
    _selectedRects = null;
    _containesCursor = null;
    if (attached && containsCursor()) {
      cursorController.addListener(markNeedsLayout);
      cursorController.color.addListener(markNeedsPaint);
    }

    if (containsSelection || containsTextSelection()) {
      markNeedsPaint();
    }
  }

  Line get line => _line;

  set line(Line value) {
    if (_line == value) {
      return;
    }
    _line = value;
    _containesCursor = null;
    markNeedsLayout();
  }

  EdgeInsetsGeometry get padding => _padding;

  set padding(EdgeInsetsGeometry value) {
    assert(value.isNonNegative);
    if (_padding == value) {
      return;
    }
    _padding = value;
    _resolvedPadding = null;
    markNeedsLayout();
  }

  RenderBox? get leading => _leading;

  set leading(RenderBox? value) {
    _leading = _updateChild(_leading, value, TextLineSlot.LEADING);
  }

  RenderContentProxyBox? get body => _body;

  set body(RenderContentProxyBox? value) {
    _body =
        _updateChild(_body, value, TextLineSlot.BODY) as RenderContentProxyBox?;
  }

  // Util
  bool containsTextSelection() {
    return line.documentOffset <= textSelection.end &&
        textSelection.start <= line.documentOffset + line.length - 1;
  }

  bool containsCursor() {
    return _containesCursor ??= textSelection.isCollapsed &&
        line.containsOffset(textSelection.baseOffset);
  }

  RenderBox? _updateChild(
      RenderBox? oldChild, RenderBox? newChild, TextLineSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      children.remove(slot);
    }
    if (newChild != null) {
      children[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  List<TextBox> _getBoxes(TextSelection textSelection) {
    final parentData = _body!.parentData as BoxParentData?;
    return _body!.getBoxesForSelection(textSelection).map((box) {
      return TextBox.fromLTRBD(
        box.left + parentData!.offset.dx,
        box.top + parentData.offset.dy,
        box.right + parentData.offset.dx,
        box.bottom + parentData.offset.dy,
        box.direction,
      );
    }).toList(growable: false);
  }

  void _resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = padding.resolve(textDirection);
    assert(_resolvedPadding!.isNonNegative);
  }

  // System Override: Selection && Cursor
  @override
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection) {
    return _getEndpointForSelection(textSelection, true);
  }

  @override
  TextSelectionPoint getExtentEndpointForSelection(
      TextSelection textSelection) {
    return _getEndpointForSelection(textSelection, false);
  }

  TextSelectionPoint _getEndpointForSelection(
      TextSelection textSelection, bool first) {
    if (textSelection.isCollapsed) {
      return TextSelectionPoint(
        Offset(0, preferredLineHeight(textSelection.extent)) +
            getOffsetForCaret(textSelection.extent),
        null,
      );
    }
    final boxes = _getBoxes(textSelection);
    assert(boxes.isNotEmpty);
    final targetBox = first ? boxes.first : boxes.last;
    return TextSelectionPoint(
      Offset(first ? targetBox.start : targetBox.end, targetBox.bottom),
      targetBox.direction,
    );
  }

  @override
  TextRange getLineBoundary(TextPosition position) {
    final lineDy = getOffsetForCaret(position)
        .translate(0, 0.5 * preferredLineHeight(position))
        .dy;
    final lineBoxes = _getBoxes(TextSelection(
      baseOffset: 0,
      extentOffset: line.length - 1,
    ))
        .where((element) => element.top < lineDy && element.bottom > lineDy)
        .toList(growable: false);
    return TextRange(
      start: getPositionForOffset(Offset(lineBoxes.first.left, lineDy)).offset,
      end: getPositionForOffset(Offset(lineBoxes.last.right, lineDy)).offset,
    );
  }

  @override
  Offset getOffsetForCaret(TextPosition position) {
    return _body!.getOffsetForCaret(position, _caretPrototype) +
        (body!.parentData as BoxParentData).offset;
  }

  @override
  TextPosition? getPositionAbove(TextPosition position) {
    return _getPosition(position, -0.5);
  }

  @override
  TextPosition? getPositionBelow(TextPosition position) {
    return _getPosition(position, 1.5);
  }

  TextPosition? _getPosition(TextPosition textPosition, double dyScale) {
    assert(textPosition.offset < line.length);
    final offset = getOffsetForCaret(textPosition)
        .translate(0, dyScale * preferredLineHeight(textPosition));
    if (_body!.size
        .contains(offset - (_body!.parentData as BoxParentData).offset)) {
      return getPositionForOffset(offset);
    }
    return null;
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return _body!.getPositionForOffset(
        offset - (_body!.parentData as BoxParentData).offset);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return _body!.getWordBoundary(position);
  }

  @override
  double preferredLineHeight(TextPosition position) {
    return _body!.getPreferredLineHeight();
  }

  @override
  container_node.Container get container => line;

  double get cursorWidth => cursorController.style.width;

  double get cursorHeight =>
      cursorController.style.height ??
      preferredLineHeight(const TextPosition(offset: 0));

  void _computeCaretPrototype() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _caretPrototype = Rect.fromLTWH(0, 0, cursorWidth, cursorHeight + 2);
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _caretPrototype = Rect.fromLTWH(0, 2, cursorWidth, cursorHeight - 4.0);
        break;
      default:
        throw 'Invalid platform';
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    for (final child in _children) {
      child.attach(owner);
    }
    if (containsCursor()) {
      cursorController.addListener(markNeedsLayout);
      cursorController.cursorColor.addListener(markNeedsPaint);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final child in _children) {
      child.detach();
    }
    if (containsCursor()) {
      cursorController.removeListener(markNeedsLayout);
      cursorController.cursorColor.removeListener(markNeedsPaint);
    }
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final value = <DiagnosticsNode>[];
    void add(RenderBox? child, String name) {
      if (child != null) {
        value.add(child.toDiagnosticsNode(name: name));
      }
    }

    add(_leading, 'leading');
    add(_body, 'body');
    return value;
  }

  @override
  bool get sizedByParent => false;

  @override
  double computeMinIntrinsicWidth(double height) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    final leadingWidth = _leading == null
        ? 0
        : _leading!.getMinIntrinsicWidth(height - verticalPadding) as int;
    final bodyWidth = _body == null
        ? 0
        : _body!.getMinIntrinsicWidth(math.max(0, height - verticalPadding))
            as int;
    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    final leadingWidth = _leading == null
        ? 0
        : _leading!.getMaxIntrinsicWidth(height - verticalPadding) as int;
    final bodyWidth = _body == null
        ? 0
        : _body!.getMaxIntrinsicWidth(math.max(0, height - verticalPadding))
            as int;
    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (_body != null) {
      return _body!
              .getMinIntrinsicHeight(math.max(0, width - horizontalPadding)) +
          verticalPadding;
    }
    return verticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding!.left + _resolvedPadding!.right;
    final verticalPadding = _resolvedPadding!.top + _resolvedPadding!.bottom;
    if (_body != null) {
      return _body!
              .getMaxIntrinsicHeight(math.max(0, width - horizontalPadding)) +
          verticalPadding;
    }
    return verticalPadding;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    _resolvePadding();
    return _body!.getDistanceToActualBaseline(baseline)! +
        _resolvedPadding!.top;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _selectedRects = null;

    _resolvePadding();
    assert(_resolvedPadding != null);

    if (_body == null && _leading == null) {
      size = constraints.constrain(Size(
        _resolvedPadding!.left + _resolvedPadding!.right,
        _resolvedPadding!.top + _resolvedPadding!.bottom,
      ));
      return;
    }

    final innerConstraints = constraints.deflate(_resolvedPadding!);
    final indentWidth = textDirection == TextDirection.ltr
        ? _resolvedPadding!.left
        : _resolvedPadding!.right;
    _body!.layout(innerConstraints, parentUsesSize: true);
    (_body!.parentData as BoxParentData).offset =
        Offset(_resolvedPadding!.left, _resolvedPadding!.top);

    if (leading != null) {
      final leadingConstraints = innerConstraints.copyWith(
        minWidth: indentWidth,
        maxWidth: indentWidth,
        maxHeight: _body!.size.height,
      );
      _leading!.layout(leadingConstraints, parentUsesSize: true);
      (_leading!.parentData as BoxParentData).offset =
          Offset(0, _resolvedPadding!.top);
    }

    size = constraints.constrain(Size(
      _resolvedPadding!.left + _body!.size.width + _resolvedPadding!.right,
      _resolvedPadding!.top + _body!.size.height + _resolvedPadding!.bottom,
    ));

    _computeCaretPrototype();
  }

  CursorPainter get _cursorPainter => CursorPainter(
        _body,
        cursorController.style,
        _caretPrototype,
        cursorController.cursorColor.value,
        devicePixelRatio,
      );

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_leading != null) {
      final parentData = _leading!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;
      context.paintChild(_leading!, effectiveOffset);
    }

    if (_body != null) {
      final parentData = _body!.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;
      if (enableInteractiveSelection &&
          line.documentOffset <= textSelection.end &&
          textSelection.start <= line.documentOffset + line.length - 1) {
        final local = localSelection(line, textSelection, false);
        _selectedRects ??= _body!.getBoxesForSelection(local);
        _paintSelection(context, effectiveOffset);
      }

      if (hasFocus &&
          cursorController.show.value &&
          containsCursor() &&
          !cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset);
      }

      context.paintChild(_body!, effectiveOffset);

      if (hasFocus &&
          cursorController.show.value &&
          containsCursor() &&
          cursorController.style.paintAboveText) {
        _paintCursor(context, effectiveOffset);
      }
    }
  }

  void _paintSelection(PaintingContext context, Offset effectiveOffset) {
    assert(_selectedRects != null);
    final paint = Paint()..color = color;
    for (final box in _selectedRects!) {
      context.canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
    }
  }

  void _paintCursor(PaintingContext context, Offset effectiveOffset) {
    final position = TextPosition(
      offset: textSelection.extentOffset - line.documentOffset,
      affinity: textSelection.base.affinity,
    );
    _cursorPainter.paint(context.canvas, effectiveOffset, position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return _children.first.hitTest(result, position: position);
  }
}

/* --------------------------------- Element -------------------------------- */

class TextLineElement extends RenderObjectElement {
  TextLineElement(EditableTextLine line) : super(line);

  final Map<TextLineSlot, Element> _slotToChildren = <TextLineSlot, Element>{};

  @override
  EditableTextLine get widget => super.widget as EditableTextLine;

  @override
  RenderEditableTextLine get renderObject =>
      super.renderObject as RenderEditableTextLine;

  @override
  void visitChildren(ElementVisitor visitor) {
    _slotToChildren.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(_slotToChildren.containsValue(child));
    assert(child.slot is TextLineSlot);
    assert(_slotToChildren.containsKey(child.slot));
    _slotToChildren.remove(child.slot);
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.leading, TextLineSlot.LEADING);
    _mountChild(widget.body, TextLineSlot.BODY);
  }

  @override
  void update(covariant EditableTextLine newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.leading, TextLineSlot.LEADING);
    _updateChild(widget.body, TextLineSlot.BODY);
  }

  @override
  void insertRenderObjectChild(RenderBox child, TextLineSlot? slot) {
    _updateRenderObject(child, slot);
    assert(renderObject.children.keys.contains(slot));
  }

  @override
  void removeRenderObjectChild(RenderObject child, TextLineSlot? slot) {
    assert(child is RenderBox);
    assert(renderObject.children[slot!] == child);
    _updateRenderObject(null, slot);
    assert(!renderObject.children.keys.contains(slot));
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, dynamic oldSlot, dynamic newSlot) {
    throw UnimplementedError();
  }

  void _mountChild(Widget? widget, TextLineSlot slot) {
    final oldChild = _slotToChildren[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      _slotToChildren.remove(slot);
    }
    if (newChild != null) {
      _slotToChildren[slot] = newChild;
    }
  }

  void _updateRenderObject(RenderBox? child, TextLineSlot? slot) {
    switch (slot) {
      case TextLineSlot.LEADING:
        renderObject.leading = child;
        break;
      case TextLineSlot.BODY:
        renderObject.body = child as RenderContentProxyBox?;
        break;
      default:
        throw UnimplementedError();
    }
  }

  void _updateChild(Widget? widget, TextLineSlot slot) {
    final oldChild = _slotToChildren[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      _slotToChildren.remove(slot);
    }
    if (newChild != null) {
      _slotToChildren[slot] = newChild;
    }
  }
}
