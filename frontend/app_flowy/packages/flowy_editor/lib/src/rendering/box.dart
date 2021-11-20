import 'package:flutter/rendering.dart';

import '../model/document/node/container.dart';

abstract class RenderContentProxyBox implements RenderBox {
  double getPreferredLineHeight();

  Offset getOffsetForCaret(TextPosition position, Rect? caretPrototype);

  TextPosition getPositionForOffset(Offset offset);

  double? getFullHeightForCaret(TextPosition position);

  TextRange getWordBoundary(TextPosition position);

  List<TextBox> getBoxesForSelection(TextSelection textSelection);
}

abstract class RenderEditableBox extends RenderBox {
  Container get container;

  double preferredLineHeight(TextPosition position);

  Offset getOffsetForCaret(TextPosition position);

  TextPosition getPositionForOffset(Offset offset);

  TextPosition? getPositionAbove(TextPosition position);

  TextPosition? getPositionBelow(TextPosition position);

  TextRange getWordBoundary(TextPosition position);

  TextRange getLineBoundary(TextPosition position);

  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection);

  TextSelectionPoint getExtentEndpointForSelection(TextSelection textSelection);
}
