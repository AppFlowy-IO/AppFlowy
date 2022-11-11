import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/flutter/overlay.dart';
import 'package:appflowy_editor/src/render/image/image_node_builder.dart';
import 'package:appflowy_editor/src/service/shortcut_event/built_in_shortcut_events.dart';
import 'package:flutter/material.dart' hide Overlay, OverlayEntry;

import 'package:appflowy_editor/src/render/editor/editor_entry.dart';
import 'package:appflowy_editor/src/render/rich_text/bulleted_list_text.dart';
import 'package:appflowy_editor/src/render/rich_text/checkbox_text.dart';
import 'package:appflowy_editor/src/render/rich_text/heading_text.dart';
import 'package:appflowy_editor/src/render/rich_text/number_list_text.dart';
import 'package:appflowy_editor/src/render/rich_text/quoted_text.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text.dart';

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
  AppFlowyEditor({
    Key? key,
    required this.editorState,
    this.customBuilders = const {},
    this.shortcutEvents = const [],
    this.selectionMenuItems = const [],
    this.editable = true,
    this.autoFocus = false,
    ThemeData? themeData,
  }) : super(key: key) {
    this.themeData = themeData ??
        ThemeData.light().copyWith(extensions: [
          ...lightEditorStyleExtension,
          ...lightPlguinStyleExtension,
        ]);
  }

  final EditorState editorState;

  /// Render plugins.
  final NodeWidgetBuilders customBuilders;

  /// Keyboard event handlers.
  final List<ShortcutEvent> shortcutEvents;

  final List<SelectionMenuItem> selectionMenuItems;

  late final ThemeData themeData;

  final bool editable;

  /// Set the value to true to focus the editor on the start of the document.
  final bool autoFocus;

  @override
  State<AppFlowyEditor> createState() => _AppFlowyEditorState();
}

class _AppFlowyEditorState extends State<AppFlowyEditor> {
  Widget? services;

  EditorState get editorState => widget.editorState;
  EditorStyle get editorStyle =>
      editorState.themeData.extension<EditorStyle>() ?? EditorStyle.light;

  @override
  void initState() {
    super.initState();

    editorState.selectionMenuItems = widget.selectionMenuItems;
    editorState.themeData = widget.themeData;
    editorState.service.renderPluginService = _createRenderPlugin();
    editorState.editable = widget.editable;

    // auto focus
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.editable && widget.autoFocus) {
        editorState.service.selectionService.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppFlowyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (editorState.service != oldWidget.editorState.service) {
      editorState.selectionMenuItems = widget.selectionMenuItems;
      editorState.service.renderPluginService = _createRenderPlugin();
    }

    editorState.themeData = widget.themeData;
    editorState.editable = widget.editable;
    services = null;
  }

  @override
  Widget build(BuildContext context) {
    services ??= _buildServices(context);
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => services!,
        ),
      ],
    );
  }

  Widget _buildServices(BuildContext context) {
    return Theme(
      data: widget.themeData,
      child: AppFlowyScroll(
        key: editorState.service.scrollServiceKey,
        child: Container(
          color: editorStyle.backgroundColor,
          padding: editorStyle.padding!,
          child: AppFlowySelection(
            key: editorState.service.selectionServiceKey,
            cursorColor: editorStyle.cursorColor!,
            selectionColor: editorStyle.selectionColor!,
            editorState: editorState,
            editable: widget.editable,
            child: AppFlowyInput(
              key: editorState.service.inputServiceKey,
              editorState: editorState,
              editable: widget.editable,
              child: AppFlowyKeyboard(
                key: editorState.service.keyboardServiceKey,
                editable: widget.editable,
                shortcutEvents: [
                  ...widget.shortcutEvents,
                  ...builtInShortcutEvents,
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
