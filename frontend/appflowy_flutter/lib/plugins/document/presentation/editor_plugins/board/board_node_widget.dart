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
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return BoardBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) =>
      node.children.isEmpty &&
      node.attributes[DatabaseBlockKeys.parentID] is String &&
      node.attributes[DatabaseBlockKeys.viewID] is String;
}

class BoardBlockComponentWidget extends BlockComponentStatefulWidget {
  const BoardBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

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
    Widget child = BuiltInPageWidget(
      node: widget.node,
      editorState: editorState,
      builder: (viewPB) {
        return BoardPage(
          key: ValueKey(viewPB.id),
          view: viewPB,
        );
      },
    );

    if (widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: widget.node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }
}
