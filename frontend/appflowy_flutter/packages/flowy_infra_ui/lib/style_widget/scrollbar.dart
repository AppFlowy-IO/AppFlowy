import 'package:flutter/material.dart';

class FlowyScrollbar extends StatefulWidget {
  const FlowyScrollbar({
    super.key,
    this.controller,
    required this.child,
  });

  final ScrollController? controller;
  final Widget child;

  @override
  State<FlowyScrollbar> createState() => _FlowyScrollbarState();
}

class _FlowyScrollbarState extends State<FlowyScrollbar> {
  final ValueNotifier<bool> isHovered = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: ValueListenableBuilder(
        valueListenable: isHovered,
        builder: (context, isHovered, child) {
          return Scrollbar(
            thumbVisibility: isHovered,
            // the radius should be fixed to 12
            radius: const Radius.circular(12),
            controller: widget.controller,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: child!,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class ScrollControllerBuilder extends StatefulWidget {
  const ScrollControllerBuilder({super.key, required this.builder});
  final ScrollControllerWidgetBuilder builder;

  @override
  State<ScrollControllerBuilder> createState() =>
      _ScrollControllerBuilderState();
}

class _ScrollControllerBuilderState extends State<ScrollControllerBuilder> {
  final ScrollController controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, controller);
  }
}

typedef ScrollControllerWidgetBuilder = Widget Function(
  BuildContext context,
  ScrollController controller,
);
