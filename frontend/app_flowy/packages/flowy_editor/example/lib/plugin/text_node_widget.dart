import 'package:flutter/material.dart';
import 'package:flowy_editor/flowy_editor.dart';

class TextNodeBuilder extends NodeWidgetBuilder {
  TextNodeBuilder.create({required super.node, required super.renderPlugins})
      : super.create();

  String get content => node.attributes['content'] as String;

  @override
  Widget build() {
    final childrenWidget = buildChildren();
    final richText = SelectableText.rich(
      TextSpan(
        text: node.attributes['content'] as String,
        style: node.attributes.toTextStyle(),
      ),
    );
    if (childrenWidget != null) {
      return Column(
        children: [
          richText,
          childrenWidget,
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
