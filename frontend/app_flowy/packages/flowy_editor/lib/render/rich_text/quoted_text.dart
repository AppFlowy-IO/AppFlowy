import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/infra/flowy_svg.dart';
import 'package:flowy_editor/render/node_widget_builder.dart';
import 'package:flowy_editor/render/rich_text/default_selectable.dart';
import 'package:flowy_editor/render/rich_text/flowy_rich_text.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/render/selection/selectable.dart';
import 'package:flutter/material.dart';

class QuotedTextNodeWidgetBuilder extends NodeWidgetBuilder {
  QuotedTextNodeWidgetBuilder.create({
    required super.editorState,
    required super.node,
    required super.key,
  }) : super.create();

  @override
  Widget build(BuildContext context) {
    return QuotedTextNodeWidget(
      key: key,
      textNode: node as TextNode,
      editorState: editorState,
    );
  }
}

class QuotedTextNodeWidget extends StatefulWidget {
  const QuotedTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final TextNode textNode;
  final EditorState editorState;

  @override
  State<QuotedTextNodeWidget> createState() => _QuotedTextNodeWidgetState();
}

// customize

class _QuotedTextNodeWidgetState extends State<QuotedTextNodeWidget>
    with Selectable, DefaultSelectable {
  final _richTextKey = GlobalKey(debugLabel: 'quoted_text');
  final leftPadding = 20.0;

  @override
  Selectable<StatefulWidget> get forward =>
      _richTextKey.currentState as Selectable;

  @override
  Offset get baseOffset {
    return Offset(leftPadding, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FlowySvg(
          name: 'quote',
        ),
        FlowyRichText(
          key: _richTextKey,
          textNode: widget.textNode,
          editorState: widget.editorState,
        ),
      ],
    );
  }
}
