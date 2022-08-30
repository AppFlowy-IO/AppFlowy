import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PopoverMutex {
  PopoverController? controller;
}

class PopoverController {
  PopoverState? state;
  PopoverMutex? mutex;

  PopoverController({this.mutex});

  close() {
    state?.close();
    if (mutex != null && mutex!.controller == this) {
      mutex!.controller = null;
    }
  }

  show() {
    if (mutex != null) {
      debugPrint("show popover");
      mutex!.controller?.close();
      mutex!.controller = this;
    }
    state?.showOverlay();
  }
}

class Popover extends StatefulWidget {
  final Widget child;
  final PopoverController? controller;
  final Offset? offset;
  final Decoration? maskDecoration;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Widget Function(BuildContext context) popupBuilder;

  const Popover({
    Key? key,
    required this.child,
    required this.popupBuilder,
    this.controller,
    this.offset,
    this.maskDecoration,
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
  }) : super(key: key);

  @override
  State<Popover> createState() => PopoverState();
}

class PopoverState extends State<Popover> {
  final LayerLink layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool hasMask = true;
  late TapGestureRecognizer _recognizer;

  static PopoverState? _popoverWithMask;

  @override
  void initState() {
    widget.controller?.state = this;
    _recognizer = TapGestureRecognizer();
    _recognizer.onTapDown = (details) {
      debugPrint("ggg tapdown");
    };
    _recognizer.onTap = (() {
      debugPrint("ggg tap");
    });
    WidgetsBinding.instance.pointerRouter
        .addGlobalRoute(_handleGlobalPointerEvent);
    super.initState();
  }

  _handleGlobalPointerEvent(PointerEvent event) {
    // debugPrint("mouse down: ${event}");
  }

  showOverlay() {
    debugPrint("show overlay");
    close();

    if (_popoverWithMask == null) {
      _popoverWithMask = this;
    } else {
      hasMask = false;
    }
    debugPrint("has mask: $hasMask");

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
    }
  }

  @override
  void deactivate() {
    debugPrint("deactivate");
    WidgetsBinding.instance.pointerRouter
        .removeGlobalRoute(_handleGlobalPointerEvent);
    close();
    super.deactivate();
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: layerLink, child: widget.child);
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
