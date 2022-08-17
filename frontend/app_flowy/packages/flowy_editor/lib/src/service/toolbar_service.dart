import 'package:flutter/material.dart';

import 'package:flowy_editor/appflowy_editor.dart';
import 'package:flowy_editor/src/render/selection/toolbar_widget.dart';
import 'package:flowy_editor/src/extensions/object_extensions.dart';

abstract class FlowyToolbarService {
  /// Show the toolbar widget beside the offset.
  void showInOffset(Offset offset, LayerLink layerLink);

  /// Hide the toolbar widget.
  void hide();
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
        handlers: const {},
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
