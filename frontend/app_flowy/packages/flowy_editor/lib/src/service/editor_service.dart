import 'package:flowy_editor/src/service/internal_key_event_handlers/default_key_event_handlers.dart';
import 'package:flutter/material.dart';

import 'package:flowy_editor/src/editor_state.dart';
import 'package:flowy_editor/src/render/editor/editor_entry.dart';
import 'package:flowy_editor/src/render/rich_text/bulleted_list_text.dart';
import 'package:flowy_editor/src/render/rich_text/checkbox_text.dart';
import 'package:flowy_editor/src/render/rich_text/heading_text.dart';
import 'package:flowy_editor/src/render/rich_text/number_list_text.dart';
import 'package:flowy_editor/src/render/rich_text/quoted_text.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text.dart';
import 'package:flowy_editor/src/service/input_service.dart';
import 'package:flowy_editor/src/service/keyboard_service.dart';
import 'package:flowy_editor/src/service/render_plugin_service.dart';
import 'package:flowy_editor/src/service/scroll_service.dart';
import 'package:flowy_editor/src/service/selection_service.dart';
import 'package:flowy_editor/src/service/toolbar_service.dart';

NodeWidgetBuilders defaultBuilders = {
  'editor': EditorEntryWidgetBuilder(),
  'text': RichTextNodeWidgetBuilder(),
  'text/checkbox': CheckboxNodeWidgetBuilder(),
  'text/heading': HeadingTextNodeWidgetBuilder(),
  'text/bulleted-list': BulletedListTextNodeWidgetBuilder(),
  'text/number-list': NumberListTextNodeWidgetBuilder(),
  'text/quote': QuotedTextNodeWidgetBuilder(),
};

class FlowyEditor extends StatefulWidget {
  const FlowyEditor({
    Key? key,
    required this.editorState,
    this.customBuilders = const {},
    this.keyEventHandlers = const [],
  }) : super(key: key);

  final EditorState editorState;

  /// Render plugins.
  final NodeWidgetBuilders customBuilders;

  /// Keyboard event handlers.
  final List<FlowyKeyEventHandler> keyEventHandlers;

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
    return FlowyScroll(
        key: editorState.service.scrollServiceKey,
        child: FlowySelection(
          key: editorState.service.selectionServiceKey,
          editorState: editorState,
          child: FlowyInput(
            key: editorState.service.inputServiceKey,
            editorState: editorState,
            child: FlowyKeyboard(
              key: editorState.service.keyboardServiceKey,
              handlers: [
                ...defaultKeyEventHandlers,
                ...widget.keyEventHandlers,
              ],
              editorState: editorState,
              child: FlowyToolbar(
                key: editorState.service.toolbarServiceKey,
                editorState: editorState,
                child:
                    editorState.service.renderPluginService.buildPluginWidget(
                  NodeWidgetContext(
                    context: context,
                    node: editorState.document.root,
                    editorState: editorState,
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  FlowyRenderPlugin _createRenderPlugin() => FlowyRenderPlugin(
        editorState: editorState,
        builders: {
          ...defaultBuilders,
          ...widget.customBuilders,
        },
      );
}
