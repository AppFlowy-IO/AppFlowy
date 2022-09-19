import 'package:appflowy_popover/src/layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'mask.dart';
import 'mutex.dart';

class PopoverController {
  PopoverState? _state;

  close() {
    _state?.close();
  }

  show() {
    _state?.showOverlay();
  }
}

class PopoverTriggerFlags {
  static int click = 0x01;
  static int hover = 0x02;
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

class Popover extends StatefulWidget {
  final PopoverController? controller;

  final Offset? offset;

  final Decoration? maskDecoration;

  /// The function used to build the popover.
  final Widget? Function(BuildContext context) popupBuilder;

  final int triggerActions;

  /// If multiple popovers are exclusive,
  /// pass the same mutex to them.
  final PopoverMutex? mutex;

  /// The direction of the popover
  final PopoverDirection direction;

  final void Function()? onClose;

  /// The content area of the popover.
  final Widget child;

  const Popover({
    Key? key,
    required this.child,
    required this.popupBuilder,
    this.controller,
    this.offset,
    this.maskDecoration,
    this.triggerActions = 0,
    this.direction = PopoverDirection.rightWithTopAligned,
    this.mutex,
    this.onClose,
  }) : super(key: key);

  @override
  State<Popover> createState() => PopoverState();
}

class PopoverState extends State<Popover> {
  final PopoverLink popoverLink = PopoverLink();
  OverlayEntry? _overlayEntry;
  bool hasMask = true;

  static PopoverState? _popoverWithMask;

  @override
  void initState() {
    widget.controller?._state = this;
    super.initState();
  }

  void showOverlay() {
    close();

    if (widget.mutex != null) {
      widget.mutex?.state = this;
    }

    if (_popoverWithMask == null) {
      _popoverWithMask = this;
    } else {
      // hasMask = false;
    }

    final newEntry = OverlayEntry(builder: (context) {
      final children = <Widget>[];

      if (hasMask) {
        children.add(PopoverMask(
          decoration: widget.maskDecoration,
          onTap: () => close(),
          onExit: () => close(),
        ));
      }

      children.add(PopoverContainer(
        direction: widget.direction,
        popoverLink: popoverLink,
        offset: widget.offset ?? Offset.zero,
        popupBuilder: widget.popupBuilder,
        onClose: () => close(),
        onCloseAll: () => closeAll(),
      ));

      return Stack(children: children);
    });

    _overlayEntry = newEntry;

    final OverlayState s = Overlay.of(context)!;

    Overlay.of(context)?.insert(newEntry);
  }

  void close() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;

      if (_popoverWithMask == this) {
        _popoverWithMask = null;
      }

      widget.onClose?.call();
    }

    if (widget.mutex?.state == this) {
      widget.mutex?.removeState();
    }
  }

  void closeAll() {
    _popoverWithMask?.close();
  }

  @override
  void deactivate() {
    close();
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
      onEnter: (PointerEnterEvent event) {
        if (widget.triggerActions & PopoverTriggerFlags.hover != 0) {
          showOverlay();
        }
      },
      child: Listener(
        child: widget.child,
        onPointerDown: (PointerDownEvent event) {
          if (widget.triggerActions & PopoverTriggerFlags.click != 0) {
            showOverlay();
          }
        },
      ),
    );
  }
}

class PopoverContainer extends StatefulWidget {
  final Widget? Function(BuildContext context) popupBuilder;
  final PopoverDirection direction;
  final PopoverLink popoverLink;
  final Offset offset;
  final void Function() onClose;
  final void Function() onCloseAll;

  const PopoverContainer({
    Key? key,
    required this.popupBuilder,
    required this.direction,
    required this.popoverLink,
    required this.offset,
    required this.onClose,
    required this.onCloseAll,
  }) : super(key: key);

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
    return CustomSingleChildLayout(
      delegate: PopoverLayoutDelegate(
        direction: widget.direction,
        link: widget.popoverLink,
        offset: widget.offset,
      ),
      child: widget.popupBuilder(context),
    );
  }

  close() => widget.onClose();

  closeAll() => widget.onCloseAll();
}
