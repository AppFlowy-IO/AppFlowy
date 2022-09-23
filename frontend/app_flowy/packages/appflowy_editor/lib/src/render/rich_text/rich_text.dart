import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

class RichTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return RichTextNodeWidget(
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

class RichTextNodeWidget extends BuiltInTextWidget {
  const RichTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  @override
  final TextNode textNode;
  @override
  final EditorState editorState;

  @override
  State<RichTextNodeWidget> createState() => _RichTextNodeWidgetState();
}

// customize

class _RichTextNodeWidgetState extends State<RichTextNodeWidget>
    with
        SelectableMixin,
        DefaultSelectable,
        BuiltInStyleMixin,
        BuiltInTextWidgetMixin {
  @override
  GlobalKey? get iconKey => null;

  final _richTextKey = GlobalKey(debugLabel: 'rich_text');

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Offset get baseOffset {
    return padding.topLeft;
  }

  @override
  Widget buildWithSingle(BuildContext context) {
    return Padding(
      padding: padding,
      child: FlowyRichText(
        key: _richTextKey,
        textNode: widget.textNode,
        textSpanDecorator: (textSpan) => textSpan.updateTextStyle(textStyle),
        placeholderTextSpanDecorator: (textSpan) =>
            textSpan.updateTextStyle(textStyle),
        lineHeight: widget.editorState.editorStyle.textStyle.lineHeight,
        editorState: widget.editorState,
      ),
    );
  }
}
