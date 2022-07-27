import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flowy_editor/infra/flowy_svg.dart';

class RichTextNodeWidgetBuilder extends NodeWidgetBuilder {
  RichTextNodeWidgetBuilder.create({
    required super.editorState,
    required super.node,
    required super.key,
  }) : super.create();

  @override
  Widget build(BuildContext context) {
    return FlowyRichText(
      key: key,
      textNode: node as TextNode,
      editorState: editorState,
    );
  }
}

class FlowyRichText extends StatefulWidget {
  const FlowyRichText({
    Key? key,
    this.cursorHeight,
    this.cursorWidth = 2.0,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final double? cursorHeight;
  final double cursorWidth;
  final TextNode textNode;
  final EditorState editorState;

  @override
  State<FlowyRichText> createState() => _FlowyRichTextState();
}

class _FlowyRichTextState extends State<FlowyRichText> with Selectable {
  final _textKey = GlobalKey();
  final _decorationKey = GlobalKey();

  EditorState get _editorState => widget.editorState;
  TextNode get _textNode => widget.textNode;
  RenderParagraph get _renderParagraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph;

  @override
  Widget build(BuildContext context) {
    final attributes = _textNode.attributes;
    // TODO: use factory method ??
    if (attributes.list == 'todo') {
      return _buildTodoListRichText(context);
    } else if (attributes.list == 'bullet') {
      return _buildBulletedListRichText(context);
    } else if (attributes.quotes == true) {
      return _buildQuotedRichText(context);
    }
    return _buildRichText(context);
  }

  @override
  Position start() => Position(path: _textNode.path, offset: 0);

  @override
  Position end() =>
      Position(path: _textNode.path, offset: _textNode.toRawString().length);

  @override
  Rect getCursorRectInPosition(Position position) {
    final textPosition = TextPosition(offset: position.offset);
    final baseRect = frontWidgetRect();
    final cursorOffset =
        _renderParagraph.getOffsetForCaret(textPosition, Rect.zero);
    final cursorHeight = widget.cursorHeight ??
        _renderParagraph.getFullHeightForCaret(textPosition) ??
        5.0; // default height
    return Rect.fromLTWH(
      baseRect.centerRight.dx + cursorOffset.dx - (widget.cursorWidth / 2),
      cursorOffset.dy,
      widget.cursorWidth,
      cursorHeight,
    );
  }

  @override
  Position getPositionInOffset(Offset start) {
    final offset = _renderParagraph.globalToLocal(start);
    final baseOffset = _renderParagraph.getPositionForOffset(offset).offset;
    return Position(path: _textNode.path, offset: baseOffset);
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    assert(pathEquals(selection.start.path, selection.end.path) &&
        pathEquals(selection.start.path, _textNode.path));

    final textSelection = TextSelection(
      baseOffset: selection.start.offset,
      extentOffset: selection.end.offset,
    );
    final baseRect = frontWidgetRect();
    return _renderParagraph.getBoxesForSelection(textSelection).map((box) {
      final rect = box.toRect();
      return rect.translate(baseRect.centerRight.dx, 0);
    }).toList();
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    final localStart = _renderParagraph.globalToLocal(start);
    final localEnd = _renderParagraph.globalToLocal(end);
    final baseOffset = _renderParagraph.getPositionForOffset(localStart).offset;
    final extentOffset = _renderParagraph.getPositionForOffset(localEnd).offset;
    return Selection.single(
      path: _textNode.path,
      startOffset: baseOffset,
      endOffset: extentOffset,
    );
  }

  Widget _buildRichText(BuildContext context) {
    if (_textNode.children.isEmpty) {
      return _buildSingleRichText(context);
    } else {
      return _buildRichTextWithChildren(context);
    }
  }

  Widget _buildRichTextWithChildren(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSingleRichText(context),
        ..._textNode.children
            .map(
              (child) => _editorState.renderPlugins.buildWidget(
                context: NodeWidgetContext(
                  buildContext: context,
                  node: child,
                  editorState: _editorState,
                ),
              ),
            )
            .toList()
      ],
    );
  }

  Widget _buildSingleRichText(BuildContext context) {
    return Expanded(child: RichText(key: _textKey, text: _textSpan));
  }

  Widget _buildTodoListRichText(BuildContext context) {
    final name = _textNode.attributes.todo ? 'check' : 'uncheck';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          child: FlowySvg(
            name: name,
            key: _decorationKey,
            size: const Size.square(20),
          ),
          onTap: () => TransactionBuilder(_editorState)
            ..updateNode(_textNode, {
              'todo': !_textNode.attributes.todo,
            })
            ..commit(),
        ),
        _buildRichText(context),
      ],
    );
  }

  Widget _buildBulletedListRichText(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(key: _decorationKey, Icons.circle),
        _buildRichText(context),
      ],
    );
  }

  Widget _buildQuotedRichText(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(key: _decorationKey, Icons.format_quote),
        _buildRichText(context),
      ],
    );
  }

  Rect frontWidgetRect() {
    // FIXME: find a more elegant way to solve this situation.
    if (_textNode.attributes.list != null) {
      final renderBox =
          _decorationKey.currentContext?.findRenderObject() as RenderBox;
      return renderBox.localToGlobal(Offset.zero) & renderBox.size;
    }
    return Rect.zero;
  }

  TextSpan get _textSpan => TextSpan(
      children: _textNode.delta.operations
          .whereType<TextInsert>()
          .map((insert) => RichTextStyle(
                attributes: insert.attributes ?? {},
                text: insert.content,
              ).toTextSpan())
          .toList(growable: false));
}
