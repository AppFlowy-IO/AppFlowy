import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/commands/text/text_commands.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';

import 'package:appflowy_editor/src/extensions/text_style_extension.dart';
import 'package:flutter/material.dart';

class CheckboxNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return CheckboxNodeWidget(
      key: context.node.key,
      textNode: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.attributes.containsKey(BuiltInAttributeKey.checkbox);
      });
}

class CheckboxNodeWidget extends BuiltInTextWidget {
  const CheckboxNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  @override
  final TextNode textNode;
  @override
  final EditorState editorState;

  @override
  State<CheckboxNodeWidget> createState() => _CheckboxNodeWidgetState();
}

class _CheckboxNodeWidgetState extends State<CheckboxNodeWidget>
    with
        SelectableMixin,
        DefaultSelectable,
        BuiltInStyleMixin,
        BuiltInTextWidgetMixin {
  @override
  final iconKey = GlobalKey();

  final _richTextKey = GlobalKey(debugLabel: 'checkbox_text');

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Offset get baseOffset {
    return super.baseOffset.translate(0, padding.top);
  }

  @override
  Widget buildWithSingle(BuildContext context) {
    final check = widget.textNode.attributes.check;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: iconKey,
            child: FlowySvg(
              width: iconSize?.width,
              height: iconSize?.height,
              padding: iconPadding,
              name: check ? 'check' : 'uncheck',
            ),
            onTap: () async {
              await widget.editorState.formatTextToCheckbox(
                widget.editorState,
                !check,
                textNode: widget.textNode,
              );
            },
          ),
          Flexible(
            child: FlowyRichText(
              key: _richTextKey,
              placeholderText: 'To-do',
              lineHeight: widget.editorState.editorStyle.textStyle.lineHeight,
              textNode: widget.textNode,
              textSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(textStyle),
              placeholderTextSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(textStyle),
              editorState: widget.editorState,
            ),
          ),
        ],
      ),
    );
  }
}
