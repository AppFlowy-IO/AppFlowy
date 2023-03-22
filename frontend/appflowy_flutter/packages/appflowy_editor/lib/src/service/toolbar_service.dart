import 'package:appflowy_editor/src/flutter/overlay.dart';
import 'package:flutter/material.dart' hide Overlay, OverlayEntry;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_widget.dart';
import 'package:appflowy_editor/src/extensions/object_extensions.dart';

abstract class AppFlowyToolbarService {
  /// Show the toolbar widget beside the offset.
  void showInOffset(
    Offset offset,
    Alignment alignment,
    LayerLink layerLink,
  );

  /// Hide the toolbar widget.
  void hide();

  /// Trigger the specified handler.
  bool triggerHandler(String id);
}

class FlowyToolbar extends StatefulWidget {
  const FlowyToolbar({
    Key? key,
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final Widget child;

  @override
  State<FlowyToolbar> createState() => _FlowyToolbarState();
}

class _FlowyToolbarState extends State<FlowyToolbar>
    implements AppFlowyToolbarService {
  OverlayEntry? _toolbarOverlay;
  final _toolbarWidgetKey = GlobalKey(debugLabel: '_toolbar_widget');
  late final List<ToolbarItem> toolbarItems;

  @override
  void initState() {
    super.initState();

    toolbarItems = [...defaultToolbarItems, ...widget.editorState.toolbarItems]
      ..sort((a, b) => a.type.compareTo(b.type));
  }

  @override
  void showInOffset(
    Offset offset,
    Alignment alignment,
    LayerLink layerLink,
  ) {
    hide();
    final items = _filterItems(toolbarItems);
    if (items.isEmpty) {
      return;
    }
    _toolbarOverlay = OverlayEntry(
      builder: (context) => ToolbarWidget(
        key: _toolbarWidgetKey,
        editorState: widget.editorState,
        layerLink: layerLink,
        offset: offset,
        items: items,
        alignment: alignment,
      ),
    );
    Overlay.of(context)?.insert(_toolbarOverlay!);
  }

  @override
  void hide() {
    _toolbarWidgetKey.currentState?.unwrapOrNull<ToolbarMixin>()?.hide();
    _toolbarOverlay?.remove();
    _toolbarOverlay = null;
  }

  @override
  bool triggerHandler(String id) {
    final items = toolbarItems.where((item) => item.id == id);
    if (items.length != 1) {
      assert(items.length == 1, 'The toolbar item\'s id must be unique');
      return false;
    }
    items.first.handler?.call(widget.editorState, context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }

  @override
  void dispose() {
    hide();

    super.dispose();
  }

  // Filter items that should not be displayed, sort according to type,
  // and insert dividers between different types.
  List<ToolbarItem> _filterItems(List<ToolbarItem> items) {
    final filterItems = items
        .where((item) => item.validator(widget.editorState))
        .toList(growable: false)
      ..sort((a, b) => a.type.compareTo(b.type));
    if (filterItems.isEmpty) {
      return [];
    }
    final List<ToolbarItem> dividedItems = [filterItems.first];
    for (var i = 1; i < filterItems.length; i++) {
      if (filterItems[i].type != filterItems[i - 1].type) {
        dividedItems.add(ToolbarItem.divider());
      }
      dividedItems.add(filterItems[i]);
    }
    return dividedItems;
  }
}
