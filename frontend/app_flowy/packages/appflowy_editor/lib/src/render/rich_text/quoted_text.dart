import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';

class QuotedTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return QuotedTextNodeWidget(
      key: context.node.key,
      textNode: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return true;
      });
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
    with SelectableMixin, DefaultSelectable {
  @override
  final iconKey = GlobalKey();

  final _richTextKey = GlobalKey(debugLabel: 'quoted_text');
  final _iconWidth = 20.0;
  final _iconRightPadding = 5.0;

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: defaultLinePadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FlowySvg(
              key: iconKey,
              width: _iconWidth,
              padding: EdgeInsets.only(right: _iconRightPadding),
              name: 'quote',
            ),
            Flexible(
              child: FlowyRichText(
                key: _richTextKey,
                placeholderText: 'Quote',
                textNode: widget.textNode,
                editorState: widget.editorState,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
