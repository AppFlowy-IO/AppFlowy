import 'package:appflowy_popover/src/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mask.dart';
import 'mutex.dart';

class PopoverController {
  PopoverState? _state;

  void close() {
    _state?.close();
  }

  void show() {
    _state?.showOverlay();
  }
}

class PopoverTriggerFlags {
  static const int none = 0x00;
  static const int click = 0x01;
  static const int hover = 0x02;
}

enum PopoverDirection {
  // Corner aligned with a corner of the SourceWidget
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,

  // Edge aligned with a edge of the SourceWidget
  topWithLeftAligned,
  topWithCenterAligned,
  topWithRightAligned,
  rightWithTopAligned,
  rightWithCenterAligned,
  rightWithBottomAligned,
  bottomWithLeftAligned,
  bottomWithCenterAligned,
  bottomWithRightAligned,
  leftWithTopAligned,
  leftWithCenterAligned,
  leftWithBottomAligned,

  custom,
}

enum PopoverClickHandler {
  listener,
  gestureDetector,
}

class Popover extends StatefulWidget {
  const Popover({
    super.key,
    required this.child,
    required this.popupBuilder,
    this.controller,
    this.offset,
    this.triggerActions = 0,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.mutex,
    this.windowPadding,
    this.onOpen,
    this.onClose,
    this.canClose,
    this.asBarrier = false,
    this.clickHandler = PopoverClickHandler.listener,
    this.skipTraversal = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.beginScaleFactor = 1.0,
    this.endScaleFactor = 1.0,
    this.slideDistance = 5.0,
    this.debugId,
    this.maskDecoration = const BoxDecoration(
      color: Color.fromARGB(0, 244, 67, 54),
    ),
  });

  final PopoverController? controller;

  /// The offset from the [child] where the popover will be drawn
  final Offset? offset;

  /// Amount of padding between the edges of the window and the popover
  final EdgeInsets? windowPadding;

  final Decoration? maskDecoration;

  /// The function used to build the popover.
  final Widget? Function(BuildContext context) popupBuilder;

  /// Specify how the popover can be triggered when interacting with the child
  /// by supplying a bitwise-OR combination of one or more [PopoverTriggerFlags]
  final int triggerActions;

  /// If multiple popovers are exclusive,
  /// pass the same mutex to them.
  final PopoverMutex? mutex;

  /// The direction of the popover
  final PopoverDirection direction;

  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final Future<bool> Function()? canClose;

  final bool asBarrier;

  /// The widget that will be used to trigger the popover.
  ///
  /// Why do we need this?
  /// Because if the parent widget of the popover is GestureDetector,
  ///  the conflict won't be resolve by using Listener, we want these two gestures exclusive.
  final PopoverClickHandler clickHandler;

  final bool skipTraversal;

  /// Animation time of the popover.
  final Duration? animationDuration;

  /// The distance of the popover's slide animation.
  final double slideDistance;

  /// The scale factor of the popover's scale animation.
  final double beginScaleFactor;
  final double endScaleFactor;

  /// The opacity of the popover's fade animation.
  final double beginOpacity;
  final double endOpacity;

  final String? debugId;

  /// The content area of the popover.
  final Widget child;

  @override
  State<Popover> createState() => PopoverState();
}

class PopoverState extends State<Popover> with SingleTickerProviderStateMixin {
  static final RootOverlayEntry rootEntry = RootOverlayEntry();

  final PopoverLink popoverLink = PopoverLink();
  late final layoutDelegate = PopoverLayoutDelegate(
    direction: widget.direction,
    link: popoverLink,
    offset: widget.offset ?? Offset.zero,
    windowPadding: widget.windowPadding ?? EdgeInsets.zero,
  );

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<Offset> slideAnimation;

  // If the widget is disposed, prevent the animation from being called.
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();

    widget.controller?._state = this;
    _buildAnimations();
  }

  @override
  void deactivate() {
    close(
      notify: false,
      withAnimation: false,
    );

    super.deactivate();
  }

  @override
  void dispose() {
    isDisposed = true;
    animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopoverTarget(
      link: popoverLink,
      child: _buildChild(context),
    );
  }

  @override
  void reassemble() {
    // clear the overlay
    while (rootEntry.isNotEmpty) {
      rootEntry.popEntry();
    }

    super.reassemble();
  }

  void showOverlay() {
    close();

    if (widget.mutex != null) {
      widget.mutex?.state = this;
    }

    final shouldAddMask = rootEntry.isEmpty;
    rootEntry.addEntry(
      context,
      widget.debugId ?? '',
      this,
      OverlayEntry(
        builder: (context) => _buildOverlayContent(shouldAddMask),
      ),
      widget.asBarrier,
      animationController,
    );

    animationController.forward();
  }

  void close({
    bool notify = true,
    bool withAnimation = true,
  }) {
    if (rootEntry.contains(this)) {
      void callback() {
        rootEntry.removeEntry(this);
        if (notify) {
          widget.onClose?.call();
        }
      }

      if (isDisposed || !withAnimation) {
        callback();
      } else {
        animationController.reverse().then((_) => callback());
      }
    }
  }

  void _removeRootOverlay() {
    rootEntry.popEntry();

    if (widget.mutex?.state == this) {
      widget.mutex?.removeState();
    }
  }

  Widget _buildChild(BuildContext context) {
    Widget child = widget.child;

    if (widget.triggerActions == 0) {
      return child;
    }

    child = _buildClickHandler(
      child,
      () {
        widget.onOpen?.call();
        if (widget.triggerActions & PopoverTriggerFlags.click != 0) {
          showOverlay();
        }
      },
    );

    if (widget.triggerActions & PopoverTriggerFlags.hover != 0) {
      child = MouseRegion(
        onEnter: (event) => showOverlay(),
        child: child,
      );
    }

    return child;
  }

  Widget _buildClickHandler(Widget child, VoidCallback handler) {
    return switch (widget.clickHandler) {
      PopoverClickHandler.listener => Listener(
          onPointerDown: (_) => _callHandler(handler),
          child: child,
        ),
      PopoverClickHandler.gestureDetector => GestureDetector(
          onTap: () => _callHandler(handler),
          child: child,
        ),
    };
  }

  void _callHandler(VoidCallback handler) {
    if (rootEntry.contains(this)) {
      close();
    } else {
      handler();
    }
  }

  Widget _buildOverlayContent(bool shouldAddMask) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _removeRootOverlay,
      },
      child: FocusScope(
        child: Stack(
          children: [
            if (shouldAddMask) _buildMask(),
            _buildPopoverContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMask() {
    return PopoverMask(
      decoration: widget.maskDecoration,
      onTap: () async {
        if (await widget.canClose?.call() ?? true) {
          _removeRootOverlay();
        }
      },
    );
  }

  Widget _buildPopoverContainer() {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Transform.translate(
              offset: slideAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: PopoverContainer(
        delegate: layoutDelegate,
        popupBuilder: widget.popupBuilder,
        skipTraversal: widget.skipTraversal,
        onClose: close,
        onCloseAll: _removeRootOverlay,
      ),
    );
  }

  void _buildAnimations() {
    animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    fadeAnimation = _buildFadeAnimation();
    scaleAnimation = _buildScaleAnimation();
    slideAnimation = _buildSlideAnimation();
  }

  Animation<double> _buildFadeAnimation() {
    return Tween<double>(
      begin: widget.beginOpacity,
      end: widget.endOpacity,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Animation<double> _buildScaleAnimation() {
    return Tween<double>(
      begin: widget.beginScaleFactor,
      end: widget.endScaleFactor,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Animation<Offset> _buildSlideAnimation() {
    final values = _getSlideAnimationValues();
    return Tween<Offset>(
      begin: values.$1,
      end: values.$2,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      ),
    );
  }

  (Offset, Offset) _getSlideAnimationValues() {
    final slideDistance = widget.slideDistance;

    switch (widget.direction) {
      case PopoverDirection.bottomWithLeftAligned:
        return (
          Offset(-slideDistance, -slideDistance),
          Offset.zero,
        );
      case PopoverDirection.bottomWithCenterAligned:
        return (
          Offset(0, -slideDistance),
          Offset.zero,
        );
      case PopoverDirection.bottomWithRightAligned:
        return (
          Offset(slideDistance, -slideDistance),
          Offset.zero,
        );
      case PopoverDirection.topWithLeftAligned:
        return (
          Offset(-slideDistance, slideDistance),
          Offset.zero,
        );
      case PopoverDirection.topWithCenterAligned:
        return (
          Offset(0, slideDistance),
          Offset.zero,
        );
      case PopoverDirection.topWithRightAligned:
        return (
          Offset(slideDistance, slideDistance),
          Offset.zero,
        );
      case PopoverDirection.leftWithTopAligned:
      case PopoverDirection.leftWithCenterAligned:
      case PopoverDirection.leftWithBottomAligned:
        return (
          Offset(slideDistance, 0),
          Offset.zero,
        );
      case PopoverDirection.rightWithTopAligned:
      case PopoverDirection.rightWithCenterAligned:
      case PopoverDirection.rightWithBottomAligned:
        return (
          Offset(-slideDistance, 0),
          Offset.zero,
        );
      default:
        return (Offset.zero, Offset.zero);
    }
  }
}

class PopoverContainer extends StatefulWidget {
  const PopoverContainer({
    super.key,
    required this.popupBuilder,
    required this.delegate,
    required this.onClose,
    required this.onCloseAll,
    required this.skipTraversal,
  });

  final Widget? Function(BuildContext context) popupBuilder;
  final void Function() onClose;
  final void Function() onCloseAll;
  final bool skipTraversal;
  final PopoverLayoutDelegate delegate;

  @override
  State<StatefulWidget> createState() => PopoverContainerState();

  static PopoverContainerState of(BuildContext context) {
    if (context is StatefulElement && context.state is PopoverContainerState) {
      return context.state as PopoverContainerState;
    }
    return context.findAncestorStateOfType<PopoverContainerState>()!;
  }

  static PopoverContainerState? maybeOf(BuildContext context) {
    if (context is StatefulElement && context.state is PopoverContainerState) {
      return context.state as PopoverContainerState;
    }
    return context.findAncestorStateOfType<PopoverContainerState>();
  }
}

class PopoverContainerState extends State<PopoverContainer> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      skipTraversal: widget.skipTraversal,
      child: CustomSingleChildLayout(
        delegate: widget.delegate,
        child: widget.popupBuilder(context),
      ),
    );
  }

  void close() => widget.onClose();

  void closeAll() => widget.onCloseAll();
}
