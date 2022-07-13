import 'package:flutter/material.dart';
import 'package:flowy_editor/flowy_editor.dart';

class TextNodeBuilder extends NodeWidgetBuilder {
  TextNodeBuilder.create({
    required super.node,
    required super.editorState,
  }) : super.create();

  String get content => node.attributes['content'] as String;

  @override
  Widget build(BuildContext buildContext) {
    final richText = SelectableText.rich(
      TextSpan(
        text: node.attributes['content'] as String,
        style: node.attributes.toTextStyle(),
      ),
    );

    Widget? children;
    if (node.children.isNotEmpty) {
      children = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: node.children
            .map(
              (e) => renderPlugins.buildWidget(
                context: NodeWidgetContext(
                  buildContext: buildContext,
                  node: e,
                  editorState: editorState,
                ),
              ),
            )
            .toList(),
      );
    }

    if (children != null) {
      return Column(
        children: [
          richText,
          children,
        ],
      );
    } else {
      return richText;
    }
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
