import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/built_in_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BoardBlockKeys {
  const BoardBlockKeys._();

  static const String type = 'board';
}

class BoardBlockComponentBuilder extends BlockComponentBuilder {
  BoardBlockComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
  });

  @override
  final BlockComponentConfiguration configuration;

  @override
  Widget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return BoardBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
    );
  }

  @override
  bool validate(Node node) =>
      node.children.isEmpty &&
      node.attributes[DatabaseBlockKeys.kAppID] is String &&
      node.attributes[DatabaseBlockKeys.kViewID] is String;
}

class BoardBlockComponentWidget extends StatefulWidget {
  const BoardBlockComponentWidget({
    super.key,
    required this.configuration,
    required this.node,
  });

  final Node node;
  final BlockComponentConfiguration configuration;

  @override
  State<BoardBlockComponentWidget> createState() =>
      _BoardBlockComponentWidgetState();
}

class _BoardBlockComponentWidgetState extends State<BoardBlockComponentWidget>
    with BlockComponentConfigurable {
  @override
  Node get node => widget.node;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Widget build(BuildContext context) {
    final editorState = Provider.of<EditorState>(context, listen: false);
    return BuiltInPageWidget(
      node: widget.node,
      editorState: editorState,
      builder: (viewPB) {
        return BoardPage(
          key: ValueKey(viewPB.id),
          view: viewPB,
        );
      },
    );
  }
}
