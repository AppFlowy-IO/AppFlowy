import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/render/style/editor_style.dart';
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
    with SelectableMixin, DefaultSelectable, BuiltInTextWidgetMixin {
  @override
  GlobalKey? get iconKey => null;

  final _richTextKey = GlobalKey(debugLabel: 'rich_text');

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Offset get baseOffset {
    return textPadding.topLeft;
  }

  EditorStyle get style => widget.editorState.editorStyle;

  EdgeInsets get textPadding => style.textPadding!;

  TextStyle get textStyle => style.textStyle!;

  @override
  Widget buildWithSingle(BuildContext context) {
    return Padding(
      padding: textPadding,
      child: FlowyRichText(
        key: _richTextKey,
        textNode: widget.textNode,
        textSpanDecorator: (textSpan) => textSpan,
        placeholderTextSpanDecorator: (textSpan) =>
            textSpan.updateTextStyle(textStyle),
        lineHeight: widget.editorState.editorStyle.lineHeight,
        editorState: widget.editorState,
      ),
    );
  }
}
