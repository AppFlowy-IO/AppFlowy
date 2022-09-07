import 'package:flutter/material.dart';

typedef OnHeaderAddButtonClick = void Function();
typedef OnHeaderMoreButtonClick = void Function();

class AppFlowyGroupHeader extends StatefulWidget {
  final double height;
  final Widget? icon;
  final Widget? title;
  final Widget? addIcon;
  final Widget? moreIcon;
  final EdgeInsets margin;
  final OnHeaderAddButtonClick? onAddButtonClick;
  final OnHeaderMoreButtonClick? onMoreButtonClick;

  const AppFlowyGroupHeader({
    required this.height,
    this.icon,
    this.title,
    this.addIcon,
    this.moreIcon,
    this.margin = EdgeInsets.zero,
    this.onAddButtonClick,
    this.onMoreButtonClick,
    Key? key,
  }) : super(key: key);

  @override
  State<AppFlowyGroupHeader> createState() => _AppFlowyGroupHeaderState();
}

class _AppFlowyGroupHeaderState extends State<AppFlowyGroupHeader> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    if (widget.icon != null) {
      children.add(widget.icon!);
      children.add(_hSpace());
    }

    if (widget.title != null) {
      children.add(widget.title!);
      children.add(_hSpace());
    }

    if (widget.moreIcon != null) {
      // children.add(const Spacer());
      children.add(
        IconButton(
          onPressed: widget.onMoreButtonClick,
          icon: widget.moreIcon!,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      );
    }

    if (widget.addIcon != null) {
      children.add(
        IconButton(
          onPressed: widget.onAddButtonClick,
          icon: widget.addIcon!,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: widget.margin,
        child: Row(children: children),
      ),
    );
  }

  Widget _hSpace() {
    return const SizedBox(width: 6);
  }
}
