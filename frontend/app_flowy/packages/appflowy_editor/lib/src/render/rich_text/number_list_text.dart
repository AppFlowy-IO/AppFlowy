import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/render/style/plugin_style.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/extensions/attributes_extension.dart';
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

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

class NumberListTextNodeWidget extends BuiltInTextWidget {
  const NumberListTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  @override
  final TextNode textNode;
  @override
  final EditorState editorState;

  @override
  State<NumberListTextNodeWidget> createState() =>
      _NumberListTextNodeWidgetState();
}

class _NumberListTextNodeWidgetState extends State<NumberListTextNodeWidget>
    with SelectableMixin, DefaultSelectable {
  @override
  final iconKey = GlobalKey();

  final _richTextKey = GlobalKey(debugLabel: 'number_list_text');

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Offset get baseOffset {
    return super.baseOffset.translate(0, padding.top);
  }

  Color get numberColor {
    final numberColor = widget.editorState.editorStyle.style(
      widget.editorState,
      widget.textNode,
      'numberColor',
    );
    if (numberColor is Color) {
      return numberColor;
    }
    return Colors.black;
  }

  NumberListPluginStyle get style =>
      Theme.of(context).extension<NumberListPluginStyle>()!;

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
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: iconKey,
            child: icon,
          ),
          Flexible(
            child: FlowyRichText(
              key: _richTextKey,
              placeholderText: 'List',
              textNode: widget.textNode,
              editorState: widget.editorState,
              lineHeight: widget.editorState.editorStyle.textStyle.lineHeight,
              placeholderTextSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(textStyle),
              textSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(textStyle),
            ),
          ),
        ],
      ),
    );
  }
}
