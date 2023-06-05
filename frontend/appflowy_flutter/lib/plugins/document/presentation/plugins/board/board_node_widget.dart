import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/document/presentation/plugins/base/built_in_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/plugins/base/insert_page_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const String kBoardType = 'board';

class BoardNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(final NodeWidgetContext<Node> context) {
    return _BoardWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (final node) {
        return node.attributes[kViewID] is String &&
            node.attributes[kAppID] is String;
      };
}

class _BoardWidget extends StatefulWidget {
  const _BoardWidget({
    final Key? key,
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
  Widget build(final BuildContext context) {
    return BuiltInPageWidget(
      node: widget.node,
      editorState: widget.editorState,
      builder: (final viewPB) {
        return BoardPage(
          key: ValueKey(viewPB.id),
          view: viewPB,
        );
      },
    );
  }
}
