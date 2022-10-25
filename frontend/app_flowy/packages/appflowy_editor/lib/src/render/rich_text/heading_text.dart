import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/render/style/plugin_styles.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/extensions/attributes_extension.dart';
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

class HeadingTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return HeadingTextNodeWidget(
      key: context.node.key,
      textNode: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.attributes.heading != null;
      });
}

class HeadingTextNodeWidget extends BuiltInTextWidget {
  const HeadingTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  @override
  final TextNode textNode;
  @override
  final EditorState editorState;

  @override
  State<HeadingTextNodeWidget> createState() => _HeadingTextNodeWidgetState();
}

// customize
class _HeadingTextNodeWidgetState extends State<HeadingTextNodeWidget>
    with SelectableMixin, DefaultSelectable {
  @override
  GlobalKey? get iconKey => null;

  final _richTextKey = GlobalKey(debugLabel: 'heading_text');

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Offset get baseOffset {
    return padding.topLeft;
  }

  HeadingPluginStyle get style =>
      Theme.of(context).extension<HeadingPluginStyle>() ??
      HeadingPluginStyle.light;

  EdgeInsets get padding => style.padding(
        widget.editorState,
        widget.textNode,
      );

  TextStyle get textStyle => style.textStyle(
        widget.editorState,
        widget.textNode,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: FlowyRichText(
        key: _richTextKey,
        placeholderText: 'Heading',
        placeholderTextSpanDecorator: (textSpan) =>
            textSpan.updateTextStyle(textStyle),
        textSpanDecorator: (textSpan) => textSpan.updateTextStyle(textStyle),
        lineHeight: widget.editorState.editorStyle.lineHeight,
        textNode: widget.textNode,
        editorState: widget.editorState,
      ),
    );
  }
}
