import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/render/selection/toolbar_widget.dart';
import 'package:flutter/material.dart';

mixin ToolbarService {
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

class _FlowyToolbarState extends State<FlowyToolbar> with ToolbarService {
  OverlayEntry? _toolbarOverlay;

  @override
  void showInOffset(Offset offset, LayerLink layerLink) {
    _toolbarOverlay?.remove();
    _toolbarOverlay = OverlayEntry(
      builder: (context) => ToolbarWidget(
        editorState: widget.editorState,
        layerLink: layerLink,
        offset: offset.translate(0, -37.0),
        handlers: const [],
      ),
    );
    Overlay.of(context)?.insert(_toolbarOverlay!);
  }

  @override
  void hide() {
    _toolbarOverlay?.remove();
    _toolbarOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }
}
