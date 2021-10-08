import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../editor.dart';

mixin RawEditorStateSelectionDelegateMixin on EditorState
    implements TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue {
    return getTextEditingValue();
  }

  @override
  set textEditingValue(TextEditingValue value) {
    setTextEditingValue(value);
  }

  @override
  void bringIntoView(TextPosition position) {
    final localRect = getRenderEditor()!.getLocalRectForCaret(position);
    final targetOffset = _getOffsetToRevealCaret(localRect, position);

    scrollController.jumpTo(targetOffset.offset);
    getRenderEditor()!.showOnScreen(rect: targetOffset.rect);
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    // TODO: implement copySelection
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    // TODO: implement cutSelection
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) {
    // TODO: implement pasteText
    throw UnimplementedError();
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    // TODO: implement selectAll
  }

  // Finds the closest scroll offset to the current scroll offset that fully
  // reveals the given caret rect. If the given rect's main axis extent is too
  // large to be fully revealed in `renderEditable`, it will be centered along
  // the main axis.
  //
  // If this is a multiline EditableText (which means the Editable can only
  // scroll vertically), the given rect's height will first be extended to match
  // `renderEditable.preferredLineHeight`, before the target scroll offset is
  // calculated.
  RevealedOffset _getOffsetToRevealCaret(Rect rect, TextPosition position) {
    if (!scrollController.position.allowImplicitScrolling) {
      return RevealedOffset(offset: scrollController.offset, rect: rect);
    }

    final editableSize = getRenderEditor()!.size;
    final double additionalOffset;
    final Offset unitOffset;

    // The caret is vertically centered within the line. Expand the caret's
    // height so that it spans the line because we're going to ensure that the
    // entire expanded caret is scrolled into view.
    final expandedRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width,
      height:
          max(rect.height, getRenderEditor()!.preferredLineHeight(position)),
    );

    additionalOffset = expandedRect.height >= editableSize.height
        ? editableSize.height / 2 - expandedRect.center.dy
        : 0.0
            .clamp(expandedRect.bottom - editableSize.height, expandedRect.top);
    unitOffset = const Offset(0, 1);

    // No overscrolling when encountering tall fonts/scripts that extend past
    // the ascent.
    final targetOffset = (additionalOffset + scrollController.offset).clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    final offsetDelta = scrollController.offset - targetOffset;
    return RevealedOffset(
        rect: rect.shift(unitOffset * offsetDelta), offset: targetOffset);
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (getSelectionOverlay()?.toolbar != null) {
      getSelectionOverlay()?.hideToolbar();
    }
  }

  @override
  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause cause,
  ) {
    setTextEditingValue(value);
  }

  @override
  bool get cutEnabled => widget.toolbarOptions.cut && !widget.readOnly;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled => widget.toolbarOptions.selectAll;
}
