import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_popover/src/layout.dart';

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

  /// The content area of the popover.
  final Widget child;

  const Popover({
    super.key,
    required this.child,
    required this.popupBuilder,
    this.controller,
    this.offset,
    this.maskDecoration = const BoxDecoration(
      color: Color.fromARGB(0, 244, 67, 54),
    ),
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
  });

  @override
  State<Popover> createState() => PopoverState();
}

class PopoverState extends State<Popover> {
  static final RootOverlayEntry _rootEntry = RootOverlayEntry();
  final PopoverLink popoverLink = PopoverLink();

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  void showOverlay() {
    close();

    if (widget.mutex != null) {
      widget.mutex?.state = this;
    }
    final shouldAddMask = _rootEntry.isEmpty;
    final newEntry = OverlayEntry(builder: (context) {
      final children = <Widget>[];
      if (shouldAddMask) {
        children.add(
          PopoverMask(
            decoration: widget.maskDecoration,
            onTap: () async {
              if (!(await widget.canClose?.call() ?? true)) {
                return;
              }
              _removeRootOverlay();
            },
          ),
        );
      }

      children.add(
        PopoverContainer(
          direction: widget.direction,
          popoverLink: popoverLink,
          offset: widget.offset ?? Offset.zero,
          windowPadding: widget.windowPadding ?? EdgeInsets.zero,
          popupBuilder: widget.popupBuilder,
          onClose: close,
          onCloseAll: _removeRootOverlay,
          skipTraversal: widget.skipTraversal,
        ),
      );

      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _removeRootOverlay,
        },
        child: FocusScope(child: Stack(children: children)),
      );
    });
    _rootEntry.addEntry(context, this, newEntry, widget.asBarrier);
  }

  void close({
    bool notify = true,
  }) {
    if (_rootEntry.contains(this)) {
      _rootEntry.removeEntry(this);
      if (notify) {
        widget.onClose?.call();
      }
    }
  }

  void _removeRootOverlay() {
    _rootEntry.popEntry();

    if (widget.mutex?.state == this) {
      widget.mutex?.removeState();
    }
  }

  @override
  void deactivate() {
    close(notify: false);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return PopoverTarget(
      link: popoverLink,
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (widget.triggerActions == 0) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (event) {
        if (widget.triggerActions & PopoverTriggerFlags.hover != 0) {
          showOverlay();
        }
      },
      child: _buildClickHandler(
        widget.child,
        () {
          widget.onOpen?.call();
          if (widget.triggerActions & PopoverTriggerFlags.click != 0) {
            showOverlay();
          }
        },
      ),
    );
  }

  Widget _buildClickHandler(Widget child, VoidCallback handler) {
    switch (widget.clickHandler) {
      case PopoverClickHandler.listener:
        return Listener(
          onPointerDown: (_) => _callHandler(handler),
          child: child,
        );
      case PopoverClickHandler.gestureDetector:
        return GestureDetector(
          onTap: () => _callHandler(handler),
          child: child,
        );
    }
  }

  void _callHandler(VoidCallback handler) {
    if (_rootEntry.contains(this)) {
      close();
    } else {
      handler();
    }
  }
}

class PopoverContainer extends StatefulWidget {
  final Widget? Function(BuildContext context) popupBuilder;
  final PopoverDirection direction;
  final PopoverLink popoverLink;
  final Offset offset;
  final EdgeInsets windowPadding;
  final void Function() onClose;
  final void Function() onCloseAll;
  final bool skipTraversal;

  const PopoverContainer({
    super.key,
    required this.popupBuilder,
    required this.direction,
    required this.popoverLink,
    required this.offset,
    required this.windowPadding,
    required this.onClose,
    required this.onCloseAll,
    required this.skipTraversal,
  });

  @override
  State<StatefulWidget> createState() => PopoverContainerState();

  static PopoverContainerState of(BuildContext context) {
    if (context is StatefulElement && context.state is PopoverContainerState) {
      return context.state as PopoverContainerState;
    }
    final PopoverContainerState? result =
        context.findAncestorStateOfType<PopoverContainerState>();
    return result!;
  }
}

class PopoverContainerState extends State<PopoverContainer> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      skipTraversal: widget.skipTraversal,
      child: CustomSingleChildLayout(
        delegate: PopoverLayoutDelegate(
          direction: widget.direction,
          link: widget.popoverLink,
          offset: widget.offset,
          windowPadding: widget.windowPadding,
        ),
        child: widget.popupBuilder(context),
      ),
    );
  }

  void close() => widget.onClose();

  void closeAll() => widget.onCloseAll();
}
