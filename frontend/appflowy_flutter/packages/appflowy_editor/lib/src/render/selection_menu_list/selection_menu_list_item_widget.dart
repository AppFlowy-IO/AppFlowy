import 'package:appflowy_editor/src/editor_state.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/render/selection_menu_list/selection_menu_list_service.dart';
import 'package:appflowy_editor/src/render/selection_menu_list/selection_menu_list_widget.dart';

class SelectionMenuListItemWidget extends StatefulWidget {
  const SelectionMenuListItemWidget({
    Key? key,
    required this.editorState,
    required this.menuService,
    required this.item,
    required this.isSelected,
    required this.hovering,
    this.width = 290.0,
  }) : super(key: key);

  final EditorState editorState;
  final SelectionMenuListService menuService;
  final SelectionMenuListItem item;
  final double width;
  final bool isSelected;

  final void Function(bool value) hovering;

  @override
  State<SelectionMenuListItemWidget> createState() =>
      _SelectionMenuItemWidgetState();
}

class _SelectionMenuItemWidgetState extends State<SelectionMenuListItemWidget> {
  var _onHover = false;
  final containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final editorStyle = widget.editorState.editorStyle;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: containerKey,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: SizedBox(
            width: widget.width,
            child: TextButton.icon(
              icon: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(5))),
                child: widget.item
                    .icon(widget.editorState, widget.isSelected || false),
              ),
              style: ButtonStyle(
                alignment: Alignment.centerLeft,
                overlayColor: MaterialStateProperty.all(
                    editorStyle.selectionMenuItemSelectedColor),
                backgroundColor: widget.isSelected
                    ? MaterialStateProperty.all(
                        editorStyle.selectionMenuItemSelectedColor)
                    : MaterialStateProperty.all(Colors.transparent),
              ),
              label: SizedBox(
                height: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      widget.item.name,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: (widget.isSelected || _onHover)
                            ? editorStyle.selectionMenuItemSelectedTextColor
                            : editorStyle.selectionMenuItemTextColor,
                        fontSize: 15.0,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      widget.item.subtitle,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: (widget.isSelected || _onHover)
                            ? editorStyle.selectionMenuItemSelectedTextColor!
                                .withOpacity(0.8)
                            : editorStyle.selectionMenuItemTextColor!
                                .withOpacity(0.8),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
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
                widget.hovering(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}
