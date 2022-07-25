import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/render/selection/floating_shortcut_widget.dart';
import 'package:flutter/material.dart';

mixin FlowyFloatingShortCutService {
  void showInOffset(Offset offset, LayerLink layerLink);
  void hide();
}

class FloatingShortCut extends StatefulWidget {
  const FloatingShortCut({
    Key? key,
    required this.size,
    required this.editorState,
    required this.floatingShortCuts,
    required this.child,
  }) : super(key: key);

  final Size size;
  final EditorState editorState;
  final Widget child;
  final FloatingShortCuts floatingShortCuts;

  @override
  State<FloatingShortCut> createState() => _FloatingShortCutState();
}

class _FloatingShortCutState extends State<FloatingShortCut>
    with FlowyFloatingShortCutService {
  OverlayEntry? _floatintShortcutOverlay;

  @override
  void showInOffset(Offset offset, LayerLink layerLink) {
    _floatintShortcutOverlay?.remove();
    _floatintShortcutOverlay = OverlayEntry(
      builder: (context) => FloatingShortcutWidget(
          editorState: widget.editorState,
          layerLink: layerLink,
          rect: offset.translate(10, 0) & widget.size,
          floatingShortcuts: widget.floatingShortCuts),
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
