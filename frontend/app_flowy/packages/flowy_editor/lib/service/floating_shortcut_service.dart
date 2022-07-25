import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/render/selection/floating_shortcut_widget.dart';
import 'package:flutter/material.dart';

mixin FlowyFloatingShortcutService {
  /// Show the floating shortcut widget beside the offset.
  void showInOffset(Offset offset, LayerLink layerLink);

  /// Hide the floating shortcut widget.
  void hide();
}

class FloatingShortcut extends StatefulWidget {
  const FloatingShortcut({
    Key? key,
    required this.size,
    required this.editorState,
    required this.floatingShortcuts,
    required this.child,
  }) : super(key: key);

  final Size size;
  final EditorState editorState;
  final Widget child;
  final FloatingShortcuts floatingShortcuts;

  @override
  State<FloatingShortcut> createState() => _FloatingShortcutState();
}

class _FloatingShortcutState extends State<FloatingShortcut>
    with FlowyFloatingShortcutService {
  OverlayEntry? _floatintShortcutOverlay;

  @override
  void showInOffset(Offset offset, LayerLink layerLink) {
    _floatintShortcutOverlay?.remove();
    _floatintShortcutOverlay = OverlayEntry(
      builder: (context) => FloatingShortcutWidget(
          editorState: widget.editorState,
          layerLink: layerLink,
          rect: offset.translate(10, 0) & widget.size,
          floatingShortcuts: widget.floatingShortcuts),
    );
    Overlay.of(context)?.insert(_floatintShortcutOverlay!);
  }

  @override
  void hide() {
    _floatintShortcutOverlay?.remove();
    _floatintShortcutOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }
}
