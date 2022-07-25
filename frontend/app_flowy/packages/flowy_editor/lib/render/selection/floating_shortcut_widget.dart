import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

typedef FloatingShortCutHandler = void Function(
    EditorState editorState, String eventName);
typedef FloatingShortCuts = List<Map<String, FloatingShortCutHandler>>;

class FloatingShortcutWidget extends StatelessWidget {
  const FloatingShortcutWidget({
    Key? key,
    required this.editorState,
    required this.layerLink,
    required this.rect,
    required this.floatingShortcuts,
  }) : super(key: key);

  final EditorState editorState;
  final LayerLink layerLink;
  final Rect rect;
  final FloatingShortCuts floatingShortcuts;

  List<String> get _shortcutNames =>
      floatingShortcuts.map((shortcut) => shortcut.keys.first).toList();
  List<FloatingShortCutHandler> get _shortcutHandlers =>
      floatingShortcuts.map((shortcut) => shortcut.values.first).toList();

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: CompositedTransformFollower(
        link: layerLink,
        offset: rect.topLeft,
        showWhenUnlinked: true,
        child: Container(
          color: Colors.white,
          child: ListView.builder(
            itemCount: floatingShortcuts.length,
            itemBuilder: ((context, index) {
              final name = _shortcutNameInIndex(index);
              final handler = _shortCutHandlerInIndex(index);
              return Card(
                child: GestureDetector(
                  onTap: () => handler(editorState, name),
                  child: ListTile(title: Text(name)),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _shortcutNameInIndex(int index) => _shortcutNames[index];
  FloatingShortCutHandler _shortCutHandlerInIndex(int index) =>
      _shortcutHandlers[index];
}
