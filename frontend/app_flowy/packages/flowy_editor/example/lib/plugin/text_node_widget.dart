import 'package:flutter/material.dart';
import 'package:flowy_editor/flowy_editor.dart';

NodeWidgetBuilder<Node> textNodeWidgetBuilder =
    (node, renderPlugins) => TextNodeWidget(
          node: node,
          renderPlugins: renderPlugins,
        );

class TextNodeWidget extends BaseNodeWidget<Node> {
  const TextNodeWidget({
    super.key,
    required super.node,
    required super.renderPlugins,
  });

  @override
  State<TextNodeWidget> createState() => _TextNodeWidgetState();
}

class _TextNodeWidgetState extends State<TextNodeWidget> {
  Node get node => widget.node;

  @override
  Widget build(BuildContext context) {
    final childWidget = renderChildren();
    final richText = RichText(
      text: TextSpan(
        text: node.attributes['content'] as String,
        style: node.attributes.toTextStyle(),
      ),
    );
    if (childWidget != null) {
      return Column(
        children: [richText, childWidget],
      );
    } else {
      return richText;
    }
  }

  // manage children's render
  Widget? renderChildren() {
    if (node.children.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: node.children
          .map(
            (e) => widget.renderPlugins.buildWidgetWithNode(
              e,
            ),
          )
          .toList(),
    );
  }
}

extension on Attributes {
  TextStyle toTextStyle() {
    return TextStyle(
      color: this['color'] != null ? Colors.red : Colors.black,
      fontSize: this['font-size'] != null ? 30 : 15,
    );
  }
}
