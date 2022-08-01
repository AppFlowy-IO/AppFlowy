import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/render/selection/toolbar_widget.dart';
import 'package:flutter/material.dart';

mixin ToolbarService {
  /// Show the floating shortcut widget beside the offset.
  void showInOffset(Offset offset, LayerLink layerLink);

  /// Hide the floating shortcut widget.
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

class _FlowyToolbarState extends State<FlowyToolbar> with ToolbarService {
  OverlayEntry? _floatingShortcutOverlay;

  @override
  void showInOffset(Offset offset, LayerLink layerLink) {
    _floatingShortcutOverlay?.remove();
    _floatingShortcutOverlay = OverlayEntry(
      builder: (context) => ToolbarWidget(
        editorState: widget.editorState,
        layerLink: layerLink,
        offset: offset.translate(0, -37.0),
        handlers: const [],
      ),
    );
    Overlay.of(context)?.insert(_floatingShortcutOverlay!);
  }

  @override
  void hide() {
    _floatingShortcutOverlay?.remove();
    _floatingShortcutOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }
}
