import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/built_in_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GridBlockKeys {
  const GridBlockKeys._();

  static const String type = 'grid';
}

class GridBlockComponentBuilder extends BlockComponentBuilder {
  GridBlockComponentBuilder({
    this.configuration = const BlockComponentConfiguration(),
  });

  @override
  final BlockComponentConfiguration configuration;

  @override
  Widget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return GridBlockComponentWidget(
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

class GridBlockComponentWidget extends StatefulWidget {
  const GridBlockComponentWidget({
    super.key,
    required this.configuration,
    required this.node,
  });

  final Node node;
  final BlockComponentConfiguration configuration;

  @override
  State<GridBlockComponentWidget> createState() =>
      _GridBlockComponentWidgetState();
}

class _GridBlockComponentWidgetState extends State<GridBlockComponentWidget>
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
        return GridPage(
          key: ValueKey(viewPB.id),
          view: viewPB,
        );
      },
    );
  }
}
