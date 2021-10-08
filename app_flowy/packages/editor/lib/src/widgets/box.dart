import 'package:flutter/rendering.dart';

import '../models/documents/nodes/container.dart';

abstract class RenderContentProxyBox implements RenderBox {
  double getPreferredLineHeight();

  Offset getOffsetForCaret(TextPosition position, Rect? caretPrototype);

  TextPosition getPositionForOffset(Offset offset);

  double? getFullHeightForCaret(TextPosition position);

  TextRange getWordBoundary(TextPosition position);

  List<TextBox> getBoxesForSelection(TextSelection textSelection);
}

/// Base class for render boxes of editable content.
///
/// Implementations of this class usually work as a wrapper around
/// regular (non-editable) render boxes which implement
/// [RenderContentProxyBox].
abstract class RenderEditableBox extends RenderBox {
  /// The document node represented by this render box.
  Container getContainer();

  /// Returns preferred line height at specified `position` in text.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  double preferredLineHeight(TextPosition position);

  /// Returns the offset at which to paint the caret.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  Offset getOffsetForCaret(TextPosition position);

  /// Returns the position within the text for the given pixel offset.
  ///
  /// The `offset` parameter must be local to this box coordinate system.
  ///
  /// Valid only after [layout].
  TextPosition getPositionForOffset(Offset offset);

  /// Returns the position relative to the [node] content
  ///
  /// The `position` must be within the [node] content
  TextPosition globalToLocalPosition(TextPosition position);

  /// Returns the position within the text which is on the line above the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the topmost
  /// line in the text already.
  TextPosition? getPositionAbove(TextPosition position);

  /// Returns the position within the text which is on the line below the given
  /// `position`.
  ///
  /// The `position` parameter must be relative to the [node] content.
  ///
  /// Primarily used with multi-line or soft-wrapping text.
  ///
  /// Can return `null` which indicates that the `position` is at the bottommost
  /// line in the text already.
  TextPosition? getPositionBelow(TextPosition position);

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  TextRange getWordBoundary(TextPosition position);

  /// Returns the text range of the line at the given offset.
  ///
  /// The newline, if any, is included in the range.
  ///
  /// The `position` parameter must be relative to the [node]'s content.
  ///
  /// Valid only after [layout].
  TextRange getLineBoundary(TextPosition position);

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after [layout].
  // List<TextBox> getBoxesForSelection(TextSelection selection);

  /// Returns a point for the base selection handle used on touch-oriented
  /// devices.
  ///
  /// The `selection` parameter is expected to be in local offsets to this
  /// render object's [node].
  TextSelectionPoint getBaseEndpointForSelection(TextSelection textSelection);

  /// Returns a point for the extent selection handle used on touch-oriented
  /// devices.
  ///
  /// The `selection` parameter is expected to be in local offsets to this
  /// render object's [node].
  TextSelectionPoint getExtentEndpointForSelection(TextSelection textSelection);

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  Rect getLocalRectForCaret(TextPosition position);
}
