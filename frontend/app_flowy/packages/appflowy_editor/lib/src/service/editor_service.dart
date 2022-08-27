import 'package:appflowy_editor/src/render/image/image_node_builder.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_widget.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/default_key_event_handlers.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/editor/editor_entry.dart';
import 'package:appflowy_editor/src/render/rich_text/bulleted_list_text.dart';
import 'package:appflowy_editor/src/render/rich_text/checkbox_text.dart';
import 'package:appflowy_editor/src/render/rich_text/heading_text.dart';
import 'package:appflowy_editor/src/render/rich_text/number_list_text.dart';
import 'package:appflowy_editor/src/render/rich_text/quoted_text.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text.dart';
import 'package:appflowy_editor/src/service/input_service.dart';
import 'package:appflowy_editor/src/service/keyboard_service.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:appflowy_editor/src/service/scroll_service.dart';
import 'package:appflowy_editor/src/service/selection_service.dart';
import 'package:appflowy_editor/src/service/toolbar_service.dart';

NodeWidgetBuilders defaultBuilders = {
  'editor': EditorEntryWidgetBuilder(),
  'text': RichTextNodeWidgetBuilder(),
  'text/checkbox': CheckboxNodeWidgetBuilder(),
  'text/heading': HeadingTextNodeWidgetBuilder(),
  'text/bulleted-list': BulletedListTextNodeWidgetBuilder(),
  'text/number-list': NumberListTextNodeWidgetBuilder(),
  'text/quote': QuotedTextNodeWidgetBuilder(),
  'image': ImageNodeBuilder(),
};

class AppFlowyEditor extends StatefulWidget {
  const AppFlowyEditor({
    Key? key,
    required this.editorState,
    this.customBuilders = const {},
    this.keyEventHandlers = const [],
    this.selectionMenuItems = const [],
  }) : super(key: key);

  final EditorState editorState;

  /// Render plugins.
  final NodeWidgetBuilders customBuilders;

  /// Keyboard event handlers.
  final List<AppFlowyKeyEventHandler> keyEventHandlers;

  final List<SelectionMenuItem> selectionMenuItems;

  @override
  State<AppFlowyEditor> createState() => _AppFlowyEditorState();
}

class _AppFlowyEditorState extends State<AppFlowyEditor> {
  EditorState get editorState => widget.editorState;

  @override
  void initState() {
    super.initState();

    editorState.selectionMenuItems = widget.selectionMenuItems;
    editorState.service.renderPluginService = _createRenderPlugin();
  }

  @override
  void didUpdateWidget(covariant AppFlowyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (editorState.service != oldWidget.editorState.service) {
      editorState.service.renderPluginService = _createRenderPlugin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyScroll(
      key: editorState.service.scrollServiceKey,
      child: AppFlowySelection(
        key: editorState.service.selectionServiceKey,
        editorState: editorState,
        child: AppFlowyInput(
          key: editorState.service.inputServiceKey,
          editorState: editorState,
          child: AppFlowyKeyboard(
            key: editorState.service.keyboardServiceKey,
            handlers: [
              ...defaultKeyEventHandlers,
              ...widget.keyEventHandlers,
            ],
            editorState: editorState,
            child: FlowyToolbar(
              key: editorState.service.toolbarServiceKey,
              editorState: editorState,
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
      ),
    );
  }

  AppFlowyRenderPlugin _createRenderPlugin() => AppFlowyRenderPlugin(
        editorState: editorState,
        builders: {
          ...defaultBuilders,
          ...widget.customBuilders,
        },
      );
}
