import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class TableActionButton extends StatefulWidget {
  const TableActionButton({
    Key? key,
    required this.width,
    required this.height,
    required this.padding,
    required this.onPressed,
  }) : super(key: key);

  final double width, height;
  final EdgeInsetsGeometry padding;
  final Function onPressed;

  @override
  State<TableActionButton> createState() => _TableActionButtonState();
}

class _TableActionButtonState extends State<TableActionButton> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: widget.padding,
        width: widget.width,
        height: widget.height,
        child: MouseRegion(
            onEnter: (_) => setState(() => _visible = true),
            onExit: (_) => setState(() => _visible = false),
            child: Center(
              child: Visibility(
                visible: _visible,
                child: ActionMenuWidget(items: [
                  ActionMenuItem.icon(
                      iconData: Icons.add, onPressed: () => widget.onPressed()),
                ]),
              ),
            )));
  }
}
