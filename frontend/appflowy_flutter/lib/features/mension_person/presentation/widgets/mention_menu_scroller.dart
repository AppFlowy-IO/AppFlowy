import 'package:flutter/material.dart';

class MentionMenuScroller extends StatefulWidget {
  const MentionMenuScroller({super.key, required this.builder});

  final MentionMenuScrollerBuilder builder;

  @override
  State<MentionMenuScroller> createState() => _MentionMenuScrollerState();
}

class _MentionMenuScrollerState extends State<MentionMenuScroller> {
  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder.call(context, controller);
  }
}

typedef MentionMenuScrollerBuilder = Widget Function(
  BuildContext context,
  ScrollController controller,
);
