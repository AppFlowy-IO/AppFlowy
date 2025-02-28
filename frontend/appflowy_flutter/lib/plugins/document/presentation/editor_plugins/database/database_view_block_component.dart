import 'dart:async';

import 'package:appflowy/plugins/database/widgets/database_view_widget.dart';
import 'package:appflowy/plugins/document/presentation/compact_mode_event.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/built_in_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatabaseBlockKeys {
  const DatabaseBlockKeys._();

  static const String gridType = 'grid';
  static const String boardType = 'board';
  static const String calendarType = 'calendar';

  static const String parentID = 'parent_id';
  static const String viewID = 'view_id';
  static const String enableCompactMode = 'enable_compact_mode';
}

const overflowTypes = {
  DatabaseBlockKeys.gridType,
  DatabaseBlockKeys.boardType,
};

class DatabaseViewBlockComponentBuilder extends BlockComponentBuilder {
  DatabaseViewBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return DatabaseBlockComponentWidget(
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
  BlockComponentValidate get validate => (node) =>
      node.children.isEmpty &&
      node.attributes[DatabaseBlockKeys.parentID] is String &&
      node.attributes[DatabaseBlockKeys.viewID] is String;
}

class DatabaseBlockComponentWidget extends BlockComponentStatefulWidget {
  const DatabaseBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<DatabaseBlockComponentWidget> createState() =>
      _DatabaseBlockComponentWidgetState();
}

class _DatabaseBlockComponentWidgetState
    extends State<DatabaseBlockComponentWidget>
    with BlockComponentConfigurable {
  @override
  Node get node => widget.node;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  late StreamSubscription<CompactModeEvent> compactModeSubscription;
  EditorState? editorState;

  @override
  void initState() {
    super.initState();
    compactModeSubscription =
        compactModeEventBus.on<CompactModeEvent>().listen((event) {
      if (event.id != node.id) return;
      final newAttributes = {
        ...node.attributes,
        DatabaseBlockKeys.enableCompactMode: event.enable,
      };
      final theEditorState = editorState;
      if (theEditorState == null) return;
      final transaction = theEditorState.transaction;
      transaction.updateNode(node, newAttributes);
      theEditorState.apply(transaction);
    });
  }

  @override
  void dispose() {
    super.dispose();
    compactModeSubscription.cancel();
    editorState = null;
  }

  @override
  Widget build(BuildContext context) {
    final editorState = Provider.of<EditorState>(context, listen: false);
    this.editorState = editorState;
    Widget child = BuiltInPageWidget(
      node: widget.node,
      editorState: editorState,
      builder: (view) => Provider.value(
        value: ReferenceState(true),
        child: DatabaseViewWidget(
          key: ValueKey(view.id),
          view: view,
          actionBuilder: widget.actionBuilder,
          showActions: widget.showActions,
          node: widget.node,
        ),
      ),
    );

    child = FocusScope(
      skipTraversal: true,
      onFocusChange: (value) {
        if (value && keepEditorFocusNotifier.value == 0) {
          context.read<EditorState>().selection = null;
        }
      },
      child: child,
    );

    if (!editorState.editable) {
      child = IgnorePointer(
        child: child,
      );
    }

    return child;
  }
}
