import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';

class NumberListTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return NumberListTextNodeWidget(
      key: context.node.key,
      textNode: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.attributes.number != null;
      });
}

class NumberListTextNodeWidget extends StatefulWidget {
  const NumberListTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final TextNode textNode;
  final EditorState editorState;

  @override
  State<NumberListTextNodeWidget> createState() =>
      _NumberListTextNodeWidgetState();
}

// customize

class _NumberListTextNodeWidgetState extends State<NumberListTextNodeWidget>
    with Selectable, DefaultSelectable {
  @override
  final iconKey = GlobalKey();

  final _richTextKey = GlobalKey(debugLabel: 'number_list_text');
  final _iconWidth = 20.0;
  final _iconRightPadding = 5.0;

  @override
  Selectable<StatefulWidget> get forward =>
      _richTextKey.currentState as Selectable;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(bottom: defaultLinePadding),
        child: SizedBox(
          width: defaultMaxTextNodeWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowySvg(
                key: iconKey,
                width: _iconWidth,
                height: _iconWidth,
                padding: EdgeInsets.only(right: _iconRightPadding),
                number: widget.textNode.attributes.number,
              ),
              Flexible(
                child: FlowyRichText(
                  key: _richTextKey,
                  placeholderText: 'List',
                  textNode: widget.textNode,
                  editorState: widget.editorState,
                ),
              ),
            ],
          ),
        ));
  }
}
