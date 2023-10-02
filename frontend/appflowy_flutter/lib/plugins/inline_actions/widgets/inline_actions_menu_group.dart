import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class InlineActionsGroup extends StatelessWidget {
  const InlineActionsGroup({
    super.key,
    required this.result,
    required this.editorState,
    required this.menuService,
    required this.style,
    required this.onSelected,
    this.isGroupSelected = false,
    this.selectedIndex = 0,
  });

  final InlineActionsResult result;
  final EditorState editorState;
  final InlineActionsMenuService menuService;
  final InlineActionsMenuStyle style;
  final VoidCallback onSelected;

  final bool isGroupSelected;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText.medium(result.title, color: style.groupTextColor),
          const SizedBox(height: 4),
          ...result.results.mapIndexed(
            (index, item) => InlineActionsWidget(
              item: item,
              editorState: editorState,
              menuService: menuService,
              isSelected: isGroupSelected && index == selectedIndex,
              style: style,
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class InlineActionsWidget extends StatefulWidget {
  const InlineActionsWidget({
    super.key,
    required this.item,
    required this.editorState,
    required this.menuService,
    required this.isSelected,
    required this.style,
    required this.onSelected,
  });

  final InlineActionsMenuItem item;
  final EditorState editorState;
  final InlineActionsMenuService menuService;
  final bool isSelected;
  final InlineActionsMenuStyle style;
  final VoidCallback onSelected;

  @override
  State<InlineActionsWidget> createState() => _InlineActionsWidgetState();
}

class _InlineActionsWidgetState extends State<InlineActionsWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: 200,
        child: widget.item.icon != null
            ? TextButton.icon(
                onPressed: _onPressed,
                style: ButtonStyle(
                  alignment: Alignment.centerLeft,
                  backgroundColor: widget.isSelected
                      ? MaterialStateProperty.all(
                          widget.style.menuItemSelectedColor,
                        )
                      : MaterialStateProperty.all(Colors.transparent),
                ),
                icon: widget.item.icon!.call(widget.isSelected || isHovering),
                label: FlowyText.regular(
                  widget.item.label,
                  color: widget.isSelected
                      ? widget.style.menuItemSelectedTextColor
                      : widget.style.menuItemTextColor,
                ),
              )
            : TextButton(
                onPressed: _onPressed,
                style: ButtonStyle(
                  alignment: Alignment.centerLeft,
                  backgroundColor: widget.isSelected
                      ? MaterialStateProperty.all(
                          widget.style.menuItemSelectedColor,
                        )
                      : MaterialStateProperty.all(Colors.transparent),
                ),
                onHover: (value) => setState(() => isHovering = value),
                child: FlowyText.regular(
                  widget.item.label,
                  color: widget.isSelected
                      ? widget.style.menuItemSelectedTextColor
                      : widget.style.menuItemTextColor,
                ),
              ),
      ),
    );
  }

  void _onPressed() {
    widget.onSelected();
    widget.item.onSelected?.call(
      context,
      widget.editorState,
      widget.menuService,
      (0, 0),
    );
  }
}
