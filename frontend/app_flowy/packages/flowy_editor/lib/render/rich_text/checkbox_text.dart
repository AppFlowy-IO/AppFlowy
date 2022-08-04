import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/infra/flowy_svg.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/render/rich_text/default_selectable.dart';
import 'package:flowy_editor/render/rich_text/flowy_rich_text.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/render/selection/selectable.dart';
import 'package:flowy_editor/service/render_plugin_service.dart';
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
  final _richTextKey = GlobalKey(debugLabel: 'checkbox_text');

  final leftPadding = 20.0;

  @override
  Selectable<StatefulWidget> get forward =>
      _richTextKey.currentState as Selectable;

  @override
  Offset get baseOffset {
    return Offset(leftPadding, 0);
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          child: FlowySvg(
            size: Size.square(leftPadding),
            name: check ? 'check' : 'uncheck',
          ),
          onTap: () {
            debugPrint('[Checkbox] onTap...');
            TransactionBuilder(widget.editorState)
              ..updateNode(widget.textNode, {
                'checkbox': !check,
              })
              ..commit();
          },
        ),
        FlowyRichText(
          key: _richTextKey,
          textNode: widget.textNode,
          editorState: widget.editorState,
        )
      ],
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
                      NodeWidgetContext(
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
