import 'package:app_flowy/plugins/board/presentation/board_page.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/base/built_in_page_widget.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/base/insert_page_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const String kBoardType = 'board';

class BoardNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _BoardWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.attributes[kViewID] is String &&
            node.attributes[kAppID] is String;
      };
}

class _BoardWidget extends StatefulWidget {
  const _BoardWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<_BoardWidget> {
  @override
  Widget build(BuildContext context) {
    return BuiltInPageWidget(
      node: widget.node,
      editorState: widget.editorState,
      builder: (viewPB) {
        return BoardPage(
          key: ValueKey(viewPB.id),
          view: viewPB,
        );
      },
    );
  }
}
