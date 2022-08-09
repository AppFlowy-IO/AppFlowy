import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/infra/flowy_svg.dart';
import 'package:flowy_editor/render/rich_text/default_selectable.dart';
import 'package:flowy_editor/render/rich_text/flowy_rich_text.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/render/selection/selectable.dart';
import 'package:flowy_editor/service/render_plugin_service.dart';
import 'package:flutter/material.dart';

class BulletedListTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return BulletedListTextNodeWidget(
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

class BulletedListTextNodeWidget extends StatefulWidget {
  const BulletedListTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final TextNode textNode;
  final EditorState editorState;

  @override
  State<BulletedListTextNodeWidget> createState() =>
      _BulletedListTextNodeWidgetState();
}

// customize

class _BulletedListTextNodeWidgetState extends State<BulletedListTextNodeWidget>
    with Selectable, DefaultSelectable {
  @override
  final iconKey = GlobalKey();

  final _richTextKey = GlobalKey(debugLabel: 'bulleted_list_text');
  final _iconSize = 20.0;
  final _iconRightPadding = 5.0;

  @override
  Selectable<StatefulWidget> get forward =>
      _richTextKey.currentState as Selectable;

  @override
  Widget build(BuildContext context) {
    final topPadding = RichTextStyle.fromTextNode(widget.textNode).topPadding;

    return SizedBox(
      width: defaultMaxTextNodeWidth,
      child: Padding(
        padding: EdgeInsets.only(bottom: defaultLinePadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowySvg(
              key: iconKey,
              size: Size.square(_iconSize),
              padding:
                  EdgeInsets.only(top: topPadding, right: _iconRightPadding),
              name: 'point',
            ),
            Expanded(
              child: FlowyRichText(
                key: _richTextKey,
                placeholderText: 'List',
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
