import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/commands/text/text_commands.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';

import 'package:appflowy_editor/src/extensions/text_style_extension.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/extensions/theme_extension.dart';

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
    with SelectableMixin, DefaultSelectable, BuiltInTextWidgetMixin {
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

  CheckboxPluginStyle get style =>
      Theme.of(context).extensionOrNull<CheckboxPluginStyle>() ??
      CheckboxPluginStyle.light;

  EdgeInsets get padding => style.padding(
        widget.editorState,
        widget.textNode,
      );

  TextStyle get textStyle => style.textStyle(
        widget.editorState,
        widget.textNode,
      );

  Widget get icon => style.icon(
        widget.editorState,
        widget.textNode,
      );

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
            child: icon,
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
              lineHeight: widget.editorState.editorStyle.lineHeight,
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
