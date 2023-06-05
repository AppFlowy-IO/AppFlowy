import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/document/presentation/plugins/base/built_in_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/plugins/base/insert_page_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const String kGridType = 'grid';

class GridNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(final NodeWidgetContext<Node> context) {
    return _GridWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (final node) {
        return node.attributes[kAppID] is String &&
            node.attributes[kViewID] is String;
      };
}

class _GridWidget extends StatefulWidget {
  const _GridWidget({
    final Key? key,
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
  Widget build(final BuildContext context) {
    return BuiltInPageWidget(
      node: widget.node,
      editorState: widget.editorState,
      builder: (final viewPB) {
        return GridPage(
          key: ValueKey(viewPB.id),
          view: viewPB,
        );
      },
    );
  }
}
