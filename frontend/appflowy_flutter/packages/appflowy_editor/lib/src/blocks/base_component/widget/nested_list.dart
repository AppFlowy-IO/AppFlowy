import 'package:flutter/material.dart';

class PaddingNestedList extends StatelessWidget {
  const PaddingNestedList({
    super.key,
    this.padding = const EdgeInsets.only(left: 20),
    required this.child,
    required this.nestedChildren,
  });

  final EdgeInsets padding;
  final Widget child;
  final List<Widget> nestedChildren;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nestedChildren,
          ),
        ),
      ],
    );
  }
}

class NestedList extends StatefulWidget {
  const NestedList({
    super.key,
    this.child,
    this.nestedChildren = const [],
  });

  final Widget? child;
  final List<Widget> nestedChildren;

  @override
  State<NestedList> createState() => _NestedListState();
}

class _NestedListState extends State<NestedList> {
  @override
  Widget build(BuildContext context) {
    if (widget.child == null && widget.nestedChildren.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.nestedChildren,
      );
    }

    if (widget.child != null && widget.nestedChildren.isEmpty) {
      return widget.child!;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child!,
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.nestedChildren,
          ),
        ),
      ],
    );
  }
}
