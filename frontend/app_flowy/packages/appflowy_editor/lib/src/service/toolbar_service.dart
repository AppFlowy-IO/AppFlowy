import 'package:appflowy_editor/src/render/toolbar/toolbar_item.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_widget.dart';
import 'package:appflowy_editor/src/extensions/object_extensions.dart';

abstract class FlowyToolbarService {
  /// Show the toolbar widget beside the offset.
  void showInOffset(Offset offset, LayerLink layerLink);

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
    implements FlowyToolbarService {
  OverlayEntry? _toolbarOverlay;
  final _toolbarWidgetKey = GlobalKey(debugLabel: '_toolbar_widget');

  @override
  void showInOffset(Offset offset, LayerLink layerLink) {
    hide();

    _toolbarOverlay = OverlayEntry(
      builder: (context) => ToolbarWidget(
        key: _toolbarWidgetKey,
        editorState: widget.editorState,
        layerLink: layerLink,
        offset: offset.translate(0, -37.0),
        items: _filterItems(defaultToolbarItems),
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
    final items = defaultToolbarItems.where((item) => item.id == id);
    if (items.length != 1) {
      assert(items.length == 1, 'The toolbar item\'s id must be unique');
      return false;
    }
    items.first.handler(widget.editorState, context);
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
    if (items.isEmpty) {
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
