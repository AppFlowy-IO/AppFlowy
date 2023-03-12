import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_widget.dart';
import 'package:flutter/material.dart';

class SelectionMenuItemWidget extends StatefulWidget {
  const SelectionMenuItemWidget({
    Key? key,
    required this.editorState,
    required this.menuService,
    required this.item,
    required this.isSelected,
    this.width = 140.0,
  }) : super(key: key);

  final EditorState editorState;
  final SelectionMenuService menuService;
  final SelectionMenuItem item;
  final double width;
  final bool isSelected;

  @override
  State<SelectionMenuItemWidget> createState() =>
      _SelectionMenuItemWidgetState();
}

class _SelectionMenuItemWidgetState extends State<SelectionMenuItemWidget> {
  var _onHover = false;

  @override
  Widget build(BuildContext context) {
    final editorStyle = widget.editorState.editorStyle;
    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 5.0, 8.0, 5.0),
      child: SizedBox(
        width: widget.width,
        child: TextButton.icon(
          icon: widget.item
              .icon(widget.editorState, widget.isSelected || _onHover),
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            overlayColor: MaterialStateProperty.all(
                editorStyle.selectionMenuItemSelectedColor),
            backgroundColor: widget.isSelected
                ? MaterialStateProperty.all(
                    editorStyle.selectionMenuItemSelectedColor)
                : MaterialStateProperty.all(Colors.transparent),
          ),
          label: Text(
            widget.item.name,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: (widget.isSelected || _onHover)
                  ? editorStyle.selectionMenuItemSelectedTextColor
                  : editorStyle.selectionMenuItemTextColor,
              fontSize: 12.0,
            ),
          ),
          onPressed: () {
            widget.item
                .handler(widget.editorState, widget.menuService, context);
          },
          onHover: (value) {
            setState(() {
              _onHover = value;
            });
          },
        ),
      ),
    );
  }
}
