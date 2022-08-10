import 'package:flutter/material.dart';

class AppFlowyColumnItemCard extends StatefulWidget {
  final Widget? child;
  final Color backgroundColor;
  final double cornerRadius;
  final EdgeInsets margin;
  final BoxConstraints boxConstraints;

  const AppFlowyColumnItemCard({
    this.child,
    this.cornerRadius = 0.0,
    this.margin = const EdgeInsets.all(4),
    this.backgroundColor = Colors.white,
    this.boxConstraints = const BoxConstraints(minHeight: 40),
    Key? key,
  }) : super(key: key);

  @override
  State<AppFlowyColumnItemCard> createState() => _AppFlowyColumnItemCardState();
}

class _AppFlowyColumnItemCardState extends State<AppFlowyColumnItemCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        clipBehavior: Clip.hardEdge,
        constraints: widget.boxConstraints,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.cornerRadius),
        ),
        child: widget.child,
      ),
    );
  }
}
