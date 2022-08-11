import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/editor_state.dart';
import 'package:flowy_editor/src/infra/flowy_svg.dart';
import 'package:flowy_editor/src/operation/transaction_builder.dart';
import 'package:flowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:flowy_editor/src/render/rich_text/flowy_rich_text.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/src/render/selection/selectable.dart';
import 'package:flowy_editor/src/service/render_plugin_service.dart';
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
        return node.attributes.containsKey(StyleKey.checkbox);
      });
}

class CheckboxNodeWidget extends StatefulWidget {
  const CheckboxNodeWidget({
    Key? key,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final TextNode textNode;
  final EditorState editorState;

  @override
  State<CheckboxNodeWidget> createState() => _CheckboxNodeWidgetState();
}

class _CheckboxNodeWidgetState extends State<CheckboxNodeWidget>
    with Selectable, DefaultSelectable {
  @override
  final iconKey = GlobalKey();

  final _richTextKey = GlobalKey(debugLabel: 'checkbox_text');
  final _iconSize = 20.0;
  final _iconRightPadding = 5.0;

  @override
  Selectable<StatefulWidget> get forward =>
      _richTextKey.currentState as Selectable;

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
    final topPadding = RichTextStyle.fromTextNode(widget.textNode).topPadding;
    return SizedBox(
        width: defaultMaxTextNodeWidth,
        child: Padding(
          padding: EdgeInsets.only(bottom: defaultLinePadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                child: FlowySvg(
                  key: iconKey,
                  size: Size.square(_iconSize),
                  padding: EdgeInsets.only(
                      top: topPadding, right: _iconRightPadding),
                  name: check ? 'check' : 'uncheck',
                ),
                onTap: () {
                  debugPrint('[Checkbox] onTap...');
                  TransactionBuilder(widget.editorState)
                    ..updateNode(widget.textNode, {
                      StyleKey.checkbox: !check,
                    })
                    ..commit();
                },
              ),
              Expanded(
                child: FlowyRichText(
                  key: _richTextKey,
                  placeholderText: 'To-do',
                  textNode: widget.textNode,
                  textSpanDecorator: _textSpanDecorator,
                  placeholderTextSpanDecorator: _textSpanDecorator,
                  editorState: widget.editorState,
                ),
              ),
            ],
          ),
        ));
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

  TextSpan _textSpanDecorator(TextSpan textSpan) {
    return TextSpan(
      children: textSpan.children
          ?.whereType<TextSpan>()
          .map(
            (span) => TextSpan(
              text: span.text,
              style: widget.textNode.attributes.check
                  ? span.style?.copyWith(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    )
                  : span.style,
              recognizer: span.recognizer,
            ),
          )
          .toList(),
    );
  }
}
