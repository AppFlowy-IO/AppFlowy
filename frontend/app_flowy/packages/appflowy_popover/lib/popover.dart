import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PopoverMutex {
  PopoverState? state;
}

class PopoverController {
  PopoverState? state;

  close() {
    state?.close();
  }

  show() {
    state?.showOverlay();
  }
}

class PopoverTriggerActionFlags {
  static int click = 0x01;
  static int hover = 0x02;
}

class Popover extends StatefulWidget {
  final Widget child;
  final PopoverController? controller;
  final Offset? offset;
  final Decoration? maskDecoration;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Widget Function(BuildContext context) popupBuilder;
  final int triggerActions;
  final PopoverMutex? mutex;
  final void Function()? onClose;

  const Popover({
    Key? key,
    required this.child,
    required this.popupBuilder,
    this.controller,
    this.offset,
    this.maskDecoration,
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
    this.triggerActions = 0,
    this.mutex,
    this.onClose,
  }) : super(key: key);

  @override
  State<Popover> createState() => PopoverState();
}

class PopoverState extends State<Popover> {
  final LayerLink layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool hasMask = true;

  static PopoverState? _popoverWithMask;

  @override
  void initState() {
    widget.controller?.state = this;
    super.initState();
  }

  showOverlay() {
    debugPrint("show overlay");
    close();

    if (widget.mutex != null) {
      if (widget.mutex!.state != null && widget.mutex!.state != this) {
        widget.mutex!.state!.close();
      }

      widget.mutex!.state = this;
    }

    if (_popoverWithMask == null) {
      _popoverWithMask = this;
    } else {
      hasMask = false;
    }

    final newEntry = OverlayEntry(builder: (context) {
      final children = <Widget>[];

      if (hasMask) {
        children.add(_PopoverMask(
          decoration: widget.maskDecoration,
          onTap: () => close(),
          onExit: () => close(),
        ));
      }

      children.add(CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: widget.offset ?? Offset.zero,
        targetAnchor: widget.targetAnchor,
        followerAnchor: widget.followerAnchor,
        child: widget.popupBuilder(context),
      ));

      return Stack(children: children);
    });

    _overlayEntry = newEntry;

    Overlay.of(context)?.insert(newEntry);
  }

  close() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      if (_popoverWithMask == this) {
        _popoverWithMask = null;
      }
      if (widget.onClose != null) {
        widget.onClose!();
      }
    }

    if (widget.mutex?.state == this) {
      widget.mutex!.state = null;
    }
  }

  @override
  void deactivate() {
    debugPrint("deactivate");
    close();
    super.deactivate();
  }

  _handleTargetPointerDown(PointerDownEvent event) {
    if (widget.triggerActions & PopoverTriggerActionFlags.click != 0) {
      showOverlay();
    }
  }

  _handleTargetPointerEnter(PointerEnterEvent event) {
    if (widget.triggerActions & PopoverTriggerActionFlags.hover != 0) {
      showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: MouseRegion(
        onEnter: _handleTargetPointerEnter,
        child: Listener(
          onPointerDown: _handleTargetPointerDown,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PopoverMask extends StatefulWidget {
  final void Function() onTap;
  final void Function()? onExit;
  final Decoration? decoration;

  const _PopoverMask(
      {Key? key, required this.onTap, this.onExit, this.decoration})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PopoverMaskState();
}

class _PopoverMaskState extends State<_PopoverMask> {
  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    super.initState();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (widget.onExit != null) {
        widget.onExit!();
      }

      return true;
    }
    return false;
  }

  @override
  void deactivate() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        // decoration: widget.decoration,
        decoration: widget.decoration ??
            const BoxDecoration(
              color: Color.fromARGB(0, 244, 67, 54),
            ),
      ),
    );
  }
}
