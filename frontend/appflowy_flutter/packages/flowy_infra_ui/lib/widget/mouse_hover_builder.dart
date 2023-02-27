import 'package:flutter/material.dart';

typedef HoverBuilder = Widget Function(BuildContext context, bool onHover);

class MouseHoverBuilder extends StatefulWidget {
  final bool isClickable;

  const MouseHoverBuilder(
      {Key? key, required this.builder, this.isClickable = false})
      : super(key: key);

  final HoverBuilder builder;

  @override
  State<MouseHoverBuilder> createState() => _MouseHoverBuilderState();
}

class _MouseHoverBuilderState extends State<MouseHoverBuilder> {
  bool _onHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isClickable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (p) => setOnHover(true),
      onExit: (p) => setOnHover(false),
      child: widget.builder(context, _onHover),
    );
  }

  void setOnHover(bool value) => setState(() => _onHover = value);
}
