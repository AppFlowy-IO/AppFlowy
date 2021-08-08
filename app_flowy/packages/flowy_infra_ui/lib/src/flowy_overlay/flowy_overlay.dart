import 'package:dartz/dartz.dart' show Tuple3;
import 'package:flowy_infra_ui/src/flowy_overlay/overlay_layout_delegate.dart';
import 'package:flutter/material.dart';

/// Specifies how overlay are anchored to the SourceWidget
enum AnchorDirection {
  // Corner aligned with a corner of the SourceWidget
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,

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

  // Custom position
  custom,
}

/// The behaviour of overlay when overlap with anchor widget
enum OverlapBehaviour {
  /// Maintain overlay size, which may cover the anchor widget.
  none,

  /// Resize overlay to avoid overlaping the anchor widget.
  stretch,
}

// TODO: junlin - support route pop handler
/// [Unsupported] The behavior of overlay when user tapping system back button
enum OnBackBehavior {
  /// Won't handle the back action
  none,

  /// Animate to get the user's attention
  alert,

  /// Intercept the back action and abort directly
  abort,

  /// Intercept the back action and dismiss overlay
  dismiss,
}

final GlobalKey<FlowyOverlayState> _key = GlobalKey<FlowyOverlayState>();

/// Invoke this method in app generation process
TransitionBuilder overlayManagerBuilder() {
  return (context, child) {
    assert(child != null, 'Child can\'t be null.');
    return FlowyOverlay(key: _key, child: child!);
  };
}

abstract class FlowyOverlayDelegate {
  void didRemove();
}

class FlowyOverlay extends StatefulWidget {
  const FlowyOverlay({
    Key? key,
    required this.child,
    this.barrierColor = Colors.transparent,
  }) : super(key: key);

  final Widget child;

  final Color? barrierColor;

  static FlowyOverlayState of(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    FlowyOverlayState? overlayManager;
    if (rootOverlay) {
      overlayManager = context.findRootAncestorStateOfType<FlowyOverlayState>() ?? overlayManager;
    } else {
      overlayManager = overlayManager ?? context.findAncestorStateOfType<FlowyOverlayState>();
    }

    assert(() {
      if (overlayManager == null) {
        throw FlutterError(
          'Can\'t find overlay manager in current context, please check if already wrapped by overlay manager.',
        );
      }
      return true;
    }());
    return overlayManager!;
  }

  static FlowyOverlayState? maybeOf(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    FlowyOverlayState? overlayManager;
    if (rootOverlay) {
      overlayManager = context.findRootAncestorStateOfType<FlowyOverlayState>() ?? overlayManager;
    } else {
      overlayManager = overlayManager ?? context.findAncestorStateOfType<FlowyOverlayState>();
    }

    return overlayManager;
  }

  @override
  FlowyOverlayState createState() => FlowyOverlayState();
}

class FlowyOverlayState extends State<FlowyOverlay> {
  List<Tuple3<Widget, String, FlowyOverlayDelegate?>> _overlayList = [];

  /// Insert a overlay widget which frame is set by the widget, not the component.
  /// Be sure to specify the offset and size using a anchorable widget (like `Postition`, `CompositedTransformFollower`)
  void insertCustom({
    required Widget widget,
    required String identifier,
    FlowyOverlayDelegate? delegate,
  }) {
    _showOverlay(
      widget: widget,
      identifier: identifier,
      shouldAnchor: false,
      delegate: delegate,
    );
  }

  void insertWithRect({
    required Widget widget,
    required String identifier,
    required Offset anchorPosition,
    required Size anchorSize,
    AnchorDirection? anchorDirection,
    FlowyOverlayDelegate? delegate,
    OverlapBehaviour? overlapBehaviour,
  }) {
    _showOverlay(
      widget: widget,
      identifier: identifier,
      shouldAnchor: true,
      delegate: delegate,
      anchorPosition: anchorPosition,
      anchorSize: anchorSize,
      anchorDirection: anchorDirection,
      overlapBehaviour: overlapBehaviour,
    );
  }

  void insertWithAnchor({
    required Widget widget,
    required String identifier,
    required BuildContext anchorContext,
    AnchorDirection? anchorDirection,
    FlowyOverlayDelegate? delegate,
    OverlapBehaviour? overlapBehaviour,
  }) {
    _showOverlay(
      widget: widget,
      identifier: identifier,
      shouldAnchor: true,
      delegate: delegate,
      anchorContext: anchorContext,
      anchorDirection: anchorDirection,
      overlapBehaviour: overlapBehaviour,
    );
  }

  void remove(String identifier) {
    setState(() {
      final index = _overlayList.indexWhere((ele) => ele.value2 == identifier);
      _overlayList.removeAt(index).value3?.didRemove();
    });
  }

  void removeAll() {
    setState(() {
      for (var ele in _overlayList.reversed) {
        ele.value3?.didRemove();
      }
      _overlayList = [];
    });
  }

  void _markDirty() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showOverlay({
    required Widget widget,
    required String identifier,
    required bool shouldAnchor,
    Offset? anchorPosition,
    Size? anchorSize,
    AnchorDirection? anchorDirection,
    BuildContext? anchorContext,
    OverlapBehaviour? overlapBehaviour,
    FlowyOverlayDelegate? delegate,
  }) {
    Widget overlay = widget;

    if (shouldAnchor) {
      assert(
        anchorPosition != null || anchorContext != null,
        'Must provide `anchorPosition` or `anchorContext` to locating overlay.',
      );
      Offset targetAnchorPosition = anchorPosition ?? Offset.zero;
      Size targetAnchorSize = anchorSize ?? Size.zero;
      if (anchorContext != null) {
        RenderObject renderObject = anchorContext.findRenderObject()!;
        assert(
          renderObject is RenderBox,
          'Unexpect non-RenderBox render object caught.',
        );
        final renderBox = renderObject as RenderBox;
        targetAnchorPosition = renderBox.localToGlobal(Offset.zero);
        targetAnchorSize = renderBox.size;
      }
      final anchorRect = Rect.fromLTWH(
        targetAnchorPosition.dx,
        targetAnchorPosition.dy,
        targetAnchorSize.width,
        targetAnchorSize.height,
      );
      overlay = CustomSingleChildLayout(
        delegate: OverlayLayoutDelegate(
          anchorRect: anchorRect,
          anchorDirection:
              shouldAnchor ? anchorDirection ?? AnchorDirection.rightWithTopAligned : AnchorDirection.custom,
          overlapBehaviour: overlapBehaviour ?? OverlapBehaviour.stretch,
        ),
        child: widget,
      );
    }

    setState(() {
      _overlayList.add(Tuple3(overlay, identifier, delegate));
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlays = _overlayList.map((ele) => ele.value1);
    final children = <Widget>[
      widget.child,
      if (overlays.isNotEmpty)
        Container(
          color: widget.barrierColor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTapOnBackground,
          ),
        ),
    ];
    return Stack(
      children: children..addAll(overlays),
    );
  }

  void _handleTapOnBackground() {
    removeAll();
  }
}
