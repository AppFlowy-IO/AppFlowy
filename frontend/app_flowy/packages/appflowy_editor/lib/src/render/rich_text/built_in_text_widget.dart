import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

abstract class BuiltInTextWidget extends StatefulWidget {
  const BuiltInTextWidget({
    Key? key,
  }) : super(key: key);

  EditorState get editorState;
  TextNode get textNode;
}

mixin BuiltInTextWidgetMixin<T extends BuiltInTextWidget> on State<T>
    implements DefaultSelectable {
  @override
  Widget build(BuildContext context) {
    if (widget.textNode.children.isEmpty) {
      return buildWithSingle(context);
    } else {
      return buildWithChildren(context);
    }
  }

  Widget buildWithSingle(BuildContext context);

  Widget buildWithChildren(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildWithSingle(context),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: customize
            const SizedBox(
              width: 20,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
            )
          ],
        )
      ],
    );
  }
}
