import 'package:flutter/material.dart';

class AppFlowyColumnItemCard extends StatefulWidget {
  final Widget? child;
  final EdgeInsets margin;
  final BoxConstraints boxConstraints;
  final BoxDecoration decoration;

  const AppFlowyColumnItemCard({
    this.child,
    this.margin = const EdgeInsets.all(4),
    this.decoration = const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.zero,
    ),
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
      padding: widget.margin,
      child: Container(
        clipBehavior: Clip.hardEdge,
        constraints: widget.boxConstraints,
        decoration: widget.decoration,
        child: widget.child,
      ),
    );
  }
}
