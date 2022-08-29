import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppFlowyPopoverExclusive {
  AppFlowyPopoverController? controller;
}

class AppFlowyPopoverController {
  AppFlowyPopoverState? state;
  AppFlowyPopoverExclusive? exclusive;

  AppFlowyPopoverController({this.exclusive});

  close() {
    state?.close();
    if (exclusive != null && exclusive!.controller == this) {
      exclusive!.controller = null;
    }
  }

  show() {
    if (exclusive != null) {
      debugPrint("show popover");
      exclusive!.controller?.close();
      exclusive!.controller = this;
    }
    state?.showOverlay();
  }
}

class AppFlowyPopover extends StatefulWidget {
  final Widget child;
  final AppFlowyPopoverController? controller;
  final Offset? offset;
  final Decoration? maskDecoration;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Widget Function(BuildContext context) popupBuilder;

  const AppFlowyPopover({
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
  State<AppFlowyPopover> createState() => AppFlowyPopoverState();
}

final _globalPopovers = List<AppFlowyPopoverState>.empty(growable: true);

class AppFlowyPopoverState extends State<AppFlowyPopover> {
  final LayerLink layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool hasMask = true;

  @override
  void initState() {
    widget.controller?.state = this;
    super.initState();
  }

  showOverlay() {
    debugPrint("show overlay");
    _overlayEntry?.remove();

    if (_globalPopovers.isNotEmpty) {
      hasMask = false;
    }
    debugPrint("has mask: $hasMask");

    final newEntry = OverlayEntry(builder: (context) {
      final children = <Widget>[];

      if (hasMask) {
        children.add(_PopoverMask(
          decoration: widget.maskDecoration,
          onTap: () => _closeAll(),
          onExit: () => _closeAll(),
        ));
      }

      children.add(CompositedTransformFollower(
        link: layerLink,
        offset: widget.offset ?? Offset.zero,
        targetAnchor: widget.targetAnchor,
        followerAnchor: widget.followerAnchor,
        child: widget.popupBuilder(context),
      ));

      return Stack(children: children);
      // return widget.popupBuilder(context);
    });

    _globalPopovers.add(this);
    _overlayEntry = newEntry;

    Overlay.of(context)?.insert(newEntry);
  }

  _closeAll() {
    final copiedArr = [..._globalPopovers];
    for (var i = copiedArr.length - 1; i >= 0; i--) {
      copiedArr[i].close();
    }
    _globalPopovers.clear();
  }

  close() {
    if (_globalPopovers.last == this) {
      _globalPopovers.removeLast();
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    debugPrint("popover dispose");
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (hasMask) {
      debugPrint("popover len: ${_globalPopovers.length}");
    }
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
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
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
