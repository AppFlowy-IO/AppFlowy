import 'package:app_flowy/plugins/document/presentation/plugins/base/built_in_page_widget.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/base/insert_page_command.dart';
import 'package:app_flowy/plugins/grid/presentation/grid_page.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const String kGridType = 'grid';

class GridNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _GridWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.attributes[kAppID] is String &&
            node.attributes[kViewID] is String;
      };
}

class _GridWidget extends StatefulWidget {
  const _GridWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_GridWidget> createState() => _GridWidgetState();
}

class _GridWidgetState extends State<_GridWidget> {
  @override
  Widget build(BuildContext context) {
    return BuiltInPageWidget(
      node: widget.node,
      editorState: widget.editorState,
      builder: (viewPB) {
        return GridPage(
          key: ValueKey(viewPB.id),
          view: viewPB,
        );
      },
    );
  }
}
