import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

class TextWithCheckBoxNodeBuilder extends NodeWidgetBuilder {
  TextWithCheckBoxNodeBuilder.create({
    required super.node,
    required super.editorState,
    required super.key,
  }) : super.create();

  // TODO: check the type
  bool get isCompleted => node.attributes['checkbox'] as bool;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: isCompleted, onChanged: (value) {}),
        Expanded(
          child: renderPlugins.buildWidget(
            context: NodeWidgetContext(
              buildContext: context,
              node: node,
              editorState: editorState,
            ),
            withSubtype: false,
          ),
        )
      ],
    );
  }
}
