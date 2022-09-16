import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/rich_text/built_in_text_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';

import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:appflowy_editor/src/extensions/attributes_extension.dart';
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
    with SelectableMixin, DefaultSelectable, BuiltInStyleMixin {
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
  Widget build(BuildContext context) {
    if (widget.textNode.children.isEmpty) {
      return _buildWithSingle(context);
    } else {
      return _buildWithChildren(context);
    }
  }

  Widget _buildWithSingle(BuildContext context) {
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
            onTap: () {
              formatCheckbox(widget.editorState, !check);
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

  Widget _buildWithChildren(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWithSingle(context),
        Row(
          children: [
            const SizedBox(
              width: 20,
            ),
            Column(
              children: widget.textNode.children
                  .map(
                    (child) => widget.editorState.service.renderPluginService
                        .buildPluginWidget(
                      child is TextNode
                          ? NodeWidgetContext<TextNode>(
                              context: context,
                              node: child,
                              editorState: widget.editorState,
                            )
                          : NodeWidgetContext<Node>(
                              context: context,
                              node: child,
                              editorState: widget.editorState,
                            ),
                    ),
                  )
                  .toList(),
            )
          ],
        )
      ],
    );
  }
}
