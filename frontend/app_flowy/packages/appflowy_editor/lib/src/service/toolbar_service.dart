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

    final items = defaultToolbarItems
        .where((item) => item.validator(widget.editorState))
        .toList(growable: false)
      ..sort((a, b) => a.type.compareTo(b.type));
    if (items.isEmpty) {
      return;
    }
    final List<ToolbarItem> dividedItems = [items.first];
    for (var i = 1; i < items.length; i++) {
      if (items[i].type != items[i - 1].type) {
        dividedItems.add(ToolbarItem.divider());
      }
      dividedItems.add(items[i]);
    }
    _toolbarOverlay = OverlayEntry(
      builder: (context) => ToolbarWidget(
        key: _toolbarWidgetKey,
        editorState: widget.editorState,
        layerLink: layerLink,
        offset: offset.translate(0, -37.0),
        items: dividedItems,
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
}
