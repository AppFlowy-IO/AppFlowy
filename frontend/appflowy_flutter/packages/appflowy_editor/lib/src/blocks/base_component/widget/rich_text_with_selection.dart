import 'package:appflowy_editor/src/render/selection/cursor_widget.dart';
import 'package:appflowy_editor/src/render/selection/selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide Selectable;

class RichTextWithSelection extends StatefulWidget {
  const RichTextWithSelection({
    super.key,
    required this.text,
    this.textSelection,
    this.selectionColor = const Color.fromARGB(100, 33, 149, 243),
    this.cursorColor = Colors.black,
    this.cursorWidth = 1.0,
    this.cursorHeight,
  });

  final TextSpan text;

  final TextSelection? textSelection;

  /// Selection
  final Color selectionColor;

  /// Cursor color
  final Color cursorColor;

  /// The width of the cursor in logical pixels.
  final double cursorWidth;

  /// The height of the cursor in logical pixels.
  /// If null, the cursor will be the same height as the text.
  final double? cursorHeight;

  @override
  State<RichTextWithSelection> createState() => RichTextWithSelectionState();
}

// Use an overlay to show the cursor and selection area temporarily.
// It works now but I don't think it's a very efficient way.
// Optimize it.
class RichTextWithSelectionState extends State<RichTextWithSelection> {
  final GlobalKey _richTextKey = GlobalKey(debugLabel: 'Rich Text Key');
  RenderParagraph get _renderParagraph =>
      _richTextKey.currentContext?.findRenderObject() as RenderParagraph;
  final List<OverlayEntry> _selectionAreaOverlays = [];
  final List<OverlayEntry> _cursorAreaOverlays = [];

  TextSelection? _cacheSelection;

  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      updateTextSelection(widget.textSelection);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Text.rich(
        key: _richTextKey,
        widget.text,
      ),
    );
  }

  Future<void> updateTextSelection(TextSelection? textSelection) async {
    if (textSelection == _cacheSelection) {
      return;
    }

    await _clearCursor();
    await _clearSelection();

    _cacheSelection = textSelection;

    if (textSelection == null) {
      return;
    }

    if (textSelection.isCollapsed) {
      _updateCursor(textSelection.base);
    } else {
      _updateSelection(textSelection);
    }
  }

  TextPosition getTextPositionInOffset(Offset offset) {
    final localOffset = _renderParagraph.globalToLocal(offset);
    final baseOffset =
        _renderParagraph.getPositionForOffset(localOffset).offset;
    return TextPosition(offset: baseOffset);
  }

  Rect getCaretRect(TextPosition textPosition) {
    final cursorAres = _getCursorAreaForSelection(textPosition);
    if (cursorAres.isNotEmpty) {
      return cursorAres.first;
    }
    assert(false);
    return Rect.zero;
  }

  Future<void> _clearSelection() async {
    _selectionAreaOverlays
      ..forEach((area) => area.remove())
      ..clear();
  }

  Future<void> _clearCursor() async {
    print('mark: clear cursor');
    _cursorAreaOverlays
      ..forEach((area) => area.remove())
      ..clear();
  }

  Future<void> _updateSelection(TextSelection textSelection) async {
    final selectionAreas = _getSelectionAreasForSelection(textSelection);
    _selectionAreaOverlays.addAll(
      selectionAreas.map(
        (area) => OverlayEntry(
          builder: (_) => SelectionWidget(
            layerLink: _layerLink,
            rect: area,
            color: widget.selectionColor,
          ),
        ),
      ),
    );
    Overlay.of(context)?.insertAll(_selectionAreaOverlays);
  }

  Future<void> _updateCursor(TextPosition textPosition) async {
    print('mark: update cursor');
    final cursorAreas = _getCursorAreaForSelection(textPosition);
    _cursorAreaOverlays.addAll(
      cursorAreas.map(
        (area) => OverlayEntry(
          builder: (_) => CursorWidget(
            layerLink: _layerLink,
            rect: area,
            color: widget.cursorColor,
          ),
        ),
      ),
    );
    Overlay.of(context)?.insertAll(_cursorAreaOverlays);
  }

  List<Rect> _getSelectionAreasForSelection(TextSelection textSelection) {
    return _renderParagraph
        .getBoxesForSelection(textSelection)
        .map((box) => box.toRect())
        .toList(growable: false);
  }

  List<Rect> _getCursorAreaForSelection(TextPosition textPosition) {
    var caretHeight = _renderParagraph.getFullHeightForCaret(textPosition);
    var caretOffset = _renderParagraph.getOffsetForCaret(
      textPosition,
      Rect.zero,
    );
    if (widget.cursorHeight != null && caretHeight != null) {
      caretOffset = caretOffset.translate(
        0,
        (caretHeight - widget.cursorHeight!) / 2,
      );
      caretHeight = widget.cursorHeight;
    }
    assert(caretHeight != null);
    final cursorArea = Rect.fromLTWH(
      caretOffset.dx,
      caretOffset.dy,
      widget.cursorWidth,
      caretHeight!,
    );
    return [cursorArea];
  }
}
