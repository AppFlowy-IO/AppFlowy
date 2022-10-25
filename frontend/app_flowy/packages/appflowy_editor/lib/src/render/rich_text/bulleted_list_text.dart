import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/render/style/built_in_plugin_styles.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

class BulletedListTextNodeWidgetBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return BulletedListTextNodeWidget(
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

class BulletedListTextNodeWidget extends BuiltInTextWidget {
  const BulletedListTextNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  @override
  final TextNode textNode;
  @override
  final EditorState editorState;

  @override
  State<BulletedListTextNodeWidget> createState() =>
      _BulletedListTextNodeWidgetState();
}

// customize

class _BulletedListTextNodeWidgetState extends State<BulletedListTextNodeWidget>
    with SelectableMixin, DefaultSelectable, BuiltInTextWidgetMixin {
  @override
  final iconKey = GlobalKey();

  final _richTextKey = GlobalKey(debugLabel: 'bulleted_list_text');

  @override
  SelectableMixin<StatefulWidget> get forward =>
      _richTextKey.currentState as SelectableMixin;

  @override
  Offset get baseOffset {
    return super.baseOffset.translate(0, padding.top);
  }

  BulletedListPluginStyle get style =>
      Theme.of(context).extension<BulletedListPluginStyle>() ??
      BulletedListPluginStyle.light;

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
              textSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(textStyle),
              placeholderTextSpanDecorator: (textSpan) =>
                  textSpan.updateTextStyle(textStyle),
              lineHeight: widget.editorState.editorStyle.lineHeight,
              textNode: widget.textNode,
              editorState: widget.editorState,
            ),
          )
        ],
      ),
    );
  }
}
