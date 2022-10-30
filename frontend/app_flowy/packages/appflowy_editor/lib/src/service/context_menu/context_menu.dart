import 'package:appflowy_editor/src/editor_state.dart';
import 'package:flutter/material.dart';

class ContextMenuItem {
  ContextMenuItem({
    required this.name,
    required this.onPressed,
  });

  final String name;
  final void Function(EditorState editorState) onPressed;
}

class ContextMenu extends StatelessWidget {
  const ContextMenu({
    Key? key,
    required this.position,
    required this.editorState,
    required this.items,
    required this.onPressed,
  }) : super(key: key);

  final Offset position;
  final EditorState editorState;
  final List<List<ContextMenuItem>> items;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      for (var j = 0; j < items[i].length; j++) {
        var onHover = false;
        children.add(
          StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Material(
                color: editorState.editorStyle.selectionMenuBackgroundColor,
                child: InkWell(
                  hoverColor:
                      editorState.editorStyle.selectionMenuItemSelectedColor,
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onTap: () {
                    items[i][j].onPressed(editorState);
                    onPressed();
                  },
                  onHover: (value) => setState(() {
                    onHover = value;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      items[i][j].name,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14,
                        color: onHover
                            ? editorState
                                .editorStyle.selectionMenuItemSelectedTextColor
                            : editorState
                                .editorStyle.selectionMenuItemTextColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
      if (i != items.length - 1) {
        children.add(const Divider());
      }
    }

    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        constraints: const BoxConstraints(
          minWidth: 140,
        ),
        decoration: BoxDecoration(
          color: editorState.editorStyle.selectionMenuBackgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
