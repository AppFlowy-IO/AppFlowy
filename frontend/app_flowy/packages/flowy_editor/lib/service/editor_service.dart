import 'package:flutter/material.dart';

import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/render/editor/editor_entry.dart';
import 'package:flowy_editor/render/rich_text/bulleted_list_text.dart';
import 'package:flowy_editor/render/rich_text/checkbox_text.dart';
import 'package:flowy_editor/render/rich_text/flowy_rich_text.dart';
import 'package:flowy_editor/render/rich_text/heading_text.dart';
import 'package:flowy_editor/render/rich_text/number_list_text.dart';
import 'package:flowy_editor/render/rich_text/quoted_text.dart';
import 'package:flowy_editor/render/selection/floating_shortcut_widget.dart';
import 'package:flowy_editor/service/input_service.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/arrow_keys_handler.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/delete_nodes_handler.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/enter_in_edge_of_text_node_handler.dart';
import 'package:flowy_editor/service/internal_key_event_handlers/shortcut_handler.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/service/render_plugin_service.dart';
import 'package:flowy_editor/service/selection_service.dart';
import 'package:flowy_editor/service/shortcut_service.dart';

NodeWidgetBuilders defaultBuilders = {
  'editor': EditorEntryWidgetBuilder(),
  'text': RichTextNodeWidgetBuilder(),
  'text/checkbox': CheckboxNodeWidgetBuilder(),
  'text/heading': HeadingTextNodeWidgetBuilder(),
  'text/bullet-list': BulletedListTextNodeWidgetBuilder(),
  'text/number-list': NumberListTextNodeWidgetBuilder(),
  'text/quote': QuotedTextNodeWidgetBuilder(),
};

List<FlowyKeyEventHandler> defaultKeyEventHandler = [
  slashShortcutHandler,
  flowyDeleteNodesHandler,
  arrowKeysHandler,
  enterInEdgeOfTextNodeHandler,
];

class FlowyEditor extends StatefulWidget {
  const FlowyEditor({
    Key? key,
    required this.editorState,
    this.customBuilders = const {},
    this.keyEventHandlers = const [],
    this.shortcuts = const [],
  }) : super(key: key);

  final EditorState editorState;

  /// Render plugins.
  final NodeWidgetBuilders customBuilders;

  /// Keyboard event handlers.
  final List<FlowyKeyEventHandler> keyEventHandlers;

  /// Shortcuts
  final FloatingShortcuts shortcuts;

  @override
  State<FlowyEditor> createState() => _FlowyEditorState();
}

class _FlowyEditorState extends State<FlowyEditor> {
  EditorState get editorState => widget.editorState;

  @override
  void initState() {
    super.initState();

    editorState.service.renderPluginService = _createRenderPlugin();
  }

  @override
  void didUpdateWidget(covariant FlowyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (editorState.service != oldWidget.editorState.service) {
      editorState.service.renderPluginService = _createRenderPlugin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowySelection(
      key: editorState.service.selectionServiceKey,
      editorState: editorState,
      child: FlowyInput(
        key: editorState.service.inputServiceKey,
        editorState: editorState,
        child: FlowyKeyboard(
          key: editorState.service.keyboardServiceKey,
          handlers: [
            ...defaultKeyEventHandler,
            ...widget.keyEventHandlers,
          ],
          editorState: editorState,
          child: FloatingShortcut(
            key: editorState.service.floatingShortcutServiceKey,
            size: const Size(200, 150), // TODO: support customize size.
            editorState: editorState,
            floatingShortcuts: widget.shortcuts,
            child: editorState.service.renderPluginService.buildPluginWidget(
              NodeWidgetContext(
                context: context,
                node: editorState.document.root,
                editorState: editorState,
              ),
            ),
          ),
        ),
      ),
    );
  }

  FlowyRenderPlugin _createRenderPlugin() => FlowyRenderPlugin(
        editorState: editorState,
        builders: {
          ...defaultBuilders,
          ...widget.customBuilders,
        },
      );
}
