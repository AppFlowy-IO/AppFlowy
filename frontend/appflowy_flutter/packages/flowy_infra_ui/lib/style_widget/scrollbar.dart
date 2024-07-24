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
          return RawScrollbar(
            thumbVisibility: isHovered,
            // the thickness should be fixed to 4.0
            thickness: 4.0,
            // the radius should be fixed to 12
            radius: const Radius.circular(12),
            trackRadius: const Radius.circular(12),
            controller: widget.controller,
            // thumbColor: const Color(0x3F171717),
            child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: child!),
          );
        },
        child: widget.child,
      ),
    );
  }
}
