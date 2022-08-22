import 'package:flutter/material.dart';

typedef OnFooterAddButtonClick = void Function();

class AppFlowyColumnFooter extends StatefulWidget {
  final double height;
  final Widget? icon;
  final Widget? title;
  final EdgeInsets margin;
  final OnFooterAddButtonClick? onAddButtonClick;

  const AppFlowyColumnFooter({
    this.icon,
    this.title,
    this.margin = EdgeInsets.zero,
    required this.height,
    this.onAddButtonClick,
    Key? key,
  }) : super(key: key);

  @override
  State<AppFlowyColumnFooter> createState() => _AppFlowyColumnFooterState();
}

class _AppFlowyColumnFooterState extends State<AppFlowyColumnFooter> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onAddButtonClick,
      child: SizedBox(
        height: widget.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) widget.icon!,
              if (widget.title != null) widget.title!,
            ],
          ),
        ),
      ),
    );
  }
}
