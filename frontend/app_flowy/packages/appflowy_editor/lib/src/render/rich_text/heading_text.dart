import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';

class HeadingTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return HeadingTextNodeWidget(
      key: context.node.key,
      textNode: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.attributes.heading != null;
      });
}

class HeadingTextNodeWidget extends StatefulWidget {
  const HeadingTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final TextNode textNode;
  final EditorState editorState;

  @override
  State<HeadingTextNodeWidget> createState() => _HeadingTextNodeWidgetState();
}

// customize

class _HeadingTextNodeWidgetState extends State<HeadingTextNodeWidget>
    with Selectable, DefaultSelectable {
  @override
  GlobalKey? get iconKey => null;

  final _richTextKey = GlobalKey(debugLabel: 'heading_text');
  final _topPadding = 5.0;

  @override
  Selectable<StatefulWidget> get forward =>
      _richTextKey.currentState as Selectable;

  @override
  Offset get baseOffset {
    return Offset(0, _topPadding);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: _topPadding,
        bottom: defaultLinePadding,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: defaultMaxTextNodeWidth),
        child: FlowyRichText(
          key: _richTextKey,
          placeholderText: 'Heading',
          placeholderTextSpanDecorator: _placeholderTextSpanDecorator,
          textSpanDecorator: _textSpanDecorator,
          textNode: widget.textNode,
          editorState: widget.editorState,
        ),
      ),
    );
  }

  TextSpan _textSpanDecorator(TextSpan textSpan) {
    return TextSpan(
      children: textSpan.children
          ?.whereType<TextSpan>()
          .map(
            (span) => TextSpan(
              text: span.text,
              style: span.style?.copyWith(
                fontSize: widget.textNode.attributes.fontSize,
              ),
              recognizer: span.recognizer,
            ),
          )
          .toList(),
    );
  }

  TextSpan _placeholderTextSpanDecorator(TextSpan textSpan) {
    return TextSpan(
      children: textSpan.children
          ?.whereType<TextSpan>()
          .map(
            (span) => TextSpan(
              text: span.text,
              style: span.style?.copyWith(
                fontSize: widget.textNode.attributes.fontSize,
              ),
              recognizer: span.recognizer,
            ),
          )
          .toList(),
    );
  }
}
