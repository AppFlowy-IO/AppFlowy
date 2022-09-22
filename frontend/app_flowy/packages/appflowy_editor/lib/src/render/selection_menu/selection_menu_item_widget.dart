import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_widget.dart';
import 'package:flutter/material.dart';

class SelectionMenuItemWidget extends StatelessWidget {
  const SelectionMenuItemWidget({
    Key? key,
    required this.editorState,
    required this.menuService,
    required this.item,
    required this.isSelected,
    this.width = 140.0,
    this.selectedColor = const Color(0xFFE0F8FF),
  }) : super(key: key);

  final EditorState editorState;
  final SelectionMenuService menuService;
  final SelectionMenuItem item;
  final double width;
  final bool isSelected;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 5.0, 8.0, 5.0),
      child: SizedBox(
        width: width,
        child: TextButton.icon(
          icon: item.icon,
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            overlayColor: MaterialStateProperty.all(selectedColor),
            backgroundColor: isSelected
                ? MaterialStateProperty.all(selectedColor)
                : MaterialStateProperty.all(Colors.transparent),
          ),
          label: Text(
            item.name(),
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14.0,
            ),
          ),
          onPressed: () {
            item.handler(editorState, menuService, context);
          },
        ),
      ),
    );
  }
}
