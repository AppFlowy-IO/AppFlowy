import 'package:flutter/material.dart';

class AppFlowyColumnItemCard extends StatefulWidget {
  final Widget? child;
  final Color backgroundColor;
  final double cornerRadius;
  final BoxConstraints boxConstraints;

  const AppFlowyColumnItemCard({
    this.child,
    this.backgroundColor = Colors.white,
    this.cornerRadius = 0.0,
    this.boxConstraints = const BoxConstraints.tightFor(height: 60),
    Key? key,
  }) : super(key: key);

  @override
  State<AppFlowyColumnItemCard> createState() => _AppFlowyColumnItemCardState();
}

class _AppFlowyColumnItemCardState extends State<AppFlowyColumnItemCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        constraints: widget.boxConstraints,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.cornerRadius),
        ),
        child: widget.child,
      ),
    );
  }
}
