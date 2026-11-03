import 'dart:async';

import 'package:flutter/material.dart';

const secondaryViewMinimumWidth = 450.0;
const _secondaryViewResizerHoverDelay = Duration(milliseconds: 500);

class SecondaryViewResizer extends StatefulWidget {
  const SecondaryViewResizer({
    super.key,
    required this.notifier,
    required this.child,
  });

  final ValueNotifier<double> notifier;
  final Widget child;

  @override
  State<SecondaryViewResizer> createState() => _SecondaryViewResizerState();
}

class _SecondaryViewResizerState extends State<SecondaryViewResizer> {
  final overlayController = OverlayPortalController();
  final layerLink = LayerLink();

  bool isHovered = false;
  bool isDragging = false;
  Timer? _showHoverTimer;

  @override
  void initState() {
    super.initState();
    overlayController.show();
  }

  @override
  void dispose() {
    _showHoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: overlayController,
      overlayChildBuilder: (context) {
        return CompositedTransformFollower(
          showWhenUnlinked: false,
          link: layerLink,
          targetAnchor: Alignment.center,
          followerAnchor: Alignment.center,
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) {
                _showHoverTimer?.cancel();
                _showHoverTimer = Timer(
                  _secondaryViewResizerHoverDelay,
                  () {
                    if (mounted) {
                      setState(() => isHovered = true);
                    }
                  },
                );
              },
              onExit: (_) {
                _showHoverTimer?.cancel();
                setState(() => isHovered = false);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => setState(() => isDragging = true),
                onHorizontalDragUpdate: (details) {
                  final newWidth = MediaQuery.sizeOf(context).width -
                      details.globalPosition.dx;
                  if (newWidth >= secondaryViewMinimumWidth) {
                    widget.notifier.value = newWidth;
                  }
                },
                onHorizontalDragEnd: (_) => setState(() => isDragging = false),
                onHorizontalDragCancel: () =>
                    setState(() => isDragging = false),
                child: TweenAnimationBuilder(
                  tween: ColorTween(
                    end: isHovered || isDragging
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  duration: const Duration(milliseconds: 100),
                  builder: (context, color, child) {
                    return SizedBox(
                      width: 11,
                      child: Center(
                        child: Container(
                          color: color,
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompositedTransformTarget(
            link: layerLink,
            child: Container(
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
          Flexible(child: widget.child),
        ],
      ),
    );
  }
}
