// ignore_for_file: unused_element

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flowy_infra_ui/src/flowy_overlay/layout.dart';

/// Specifies how overlay are anchored to the SourceWidget
enum AnchorDirection {
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

  // Custom position
  custom,
}

/// The behaviour of overlay when overlap with anchor widget
enum OverlapBehaviour {
  /// Maintain overlay size, which may cover the anchor widget.
  none,

  /// Resize overlay to avoid overlapping the anchor widget.
  stretch,
}

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

class FlowyOverlayStyle {
  final Color barrierColor;
  bool blur;

  FlowyOverlayStyle(
      {this.barrierColor = Colors.transparent, this.blur = false});
}

final GlobalKey<FlowyOverlayState> _key = GlobalKey<FlowyOverlayState>();

/// Invoke this method in app generation process
Widget overlayManagerBuilder(BuildContext context, Widget? child) {
  assert(child != null, 'Child can\'t be null.');
  return FlowyOverlay(key: _key, child: child!);
}

abstract mixin class FlowyOverlayDelegate {
  bool asBarrier() => false;
  void didRemove() => {};
}

class FlowyOverlay extends StatefulWidget {
  const FlowyOverlay({super.key, required this.child});

  final Widget child;

  static FlowyOverlayState of(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    FlowyOverlayState? state = maybeOf(context, rootOverlay: rootOverlay);
    assert(() {
      if (state == null) {
        throw FlutterError(
          'Can\'t find overlay manager in current context, please check if already wrapped by overlay manager.',
        );
      }
      return true;
    }());
    return state!;
  }

  static FlowyOverlayState? maybeOf(
    BuildContext context, {
    bool rootOverlay = false,
  }) {
    FlowyOverlayState? state;
    if (rootOverlay) {
      state = context.findRootAncestorStateOfType<FlowyOverlayState>();
    } else {
      state = context.findAncestorStateOfType<FlowyOverlayState>();
    }
    return state;
  }

  static Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
  }) async {
    await showDialog(
      context: context,
      builder: builder,
    );
  }

  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  FlowyOverlayState createState() => FlowyOverlayState();
}

class OverlayItem {
  Widget widget;
  String identifier;
  FlowyOverlayDelegate? delegate;
  FocusNode focusNode;

  OverlayItem({
    required this.widget,
    required this.identifier,
    required this.focusNode,
    this.delegate,
  });

  void dispose() {
    focusNode.dispose();
  }
}

class FlowyOverlayState extends State<FlowyOverlay> {
  final List<OverlayItem> _overlayList = [];
  FlowyOverlayStyle style = FlowyOverlayStyle();

  final Map<ShortcutActivator, void Function(String)>
      _keyboardShortcutBindings = {};

  /// Insert a overlay widget which frame is set by the widget, not the component.
  /// Be sure to specify the offset and size using a anchorable widget (like `Position`, `CompositedTransformFollower`)
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
    FlowyOverlayStyle? style,
  }) {
    if (style != null) {
      this.style = style;
    }

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
    FlowyOverlayStyle? style,
    Offset? anchorOffset,
  }) {
    this.style = style ?? FlowyOverlayStyle();

    _showOverlay(
      widget: widget,
      identifier: identifier,
      shouldAnchor: true,
      delegate: delegate,
      anchorContext: anchorContext,
      anchorDirection: anchorDirection,
      overlapBehaviour: overlapBehaviour,
      anchorOffset: anchorOffset,
    );
  }

  void remove(String identifier) {
    setState(() {
      final index =
          _overlayList.indexWhere((item) => item.identifier == identifier);
      if (index != -1) {
        final OverlayItem item = _overlayList.removeAt(index);
        item.delegate?.didRemove();
        item.dispose();
      }
    });
  }

  void removeAll() {
    setState(() {
      if (_overlayList.isEmpty) {
        return;
      }

      final reveredList = _overlayList.reversed.toList();
      final firstItem = reveredList.removeAt(0);
      _overlayList.remove(firstItem);
      if (firstItem.delegate != null) {
        firstItem.delegate!.didRemove();
        firstItem.dispose();
        if (firstItem.delegate!.asBarrier()) {
          return;
        }
      }

      for (final element in reveredList) {
        if (element.delegate?.asBarrier() ?? false) {
          return;
        } else {
          element.delegate?.didRemove();
          element.dispose();
          _overlayList.remove(element);
        }
      }
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
    Offset? anchorOffset,
    OverlapBehaviour? overlapBehaviour,
    FlowyOverlayDelegate? delegate,
  }) {
    Widget overlay = widget;
    final offset = anchorOffset ?? Offset.zero;
    final focusNode = FocusNode();
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
          'Unexpecteded non-RenderBox render object caught.',
        );
        final renderBox = renderObject as RenderBox;
        targetAnchorPosition = renderBox.localToGlobal(Offset.zero);
        targetAnchorSize = renderBox.size;
      }
      final anchorRect = Rect.fromLTWH(
        targetAnchorPosition.dx + offset.dx,
        targetAnchorPosition.dy + offset.dy,
        targetAnchorSize.width,
        targetAnchorSize.height,
      );

      overlay = CustomSingleChildLayout(
        delegate: OverlayLayoutDelegate(
          anchorRect: anchorRect,
          anchorDirection:
              anchorDirection ?? AnchorDirection.rightWithTopAligned,
          overlapBehaviour: overlapBehaviour ?? OverlapBehaviour.stretch,
        ),
        child: Focus(
            focusNode: focusNode,
            onKeyEvent: (node, event) {
              KeyEventResult result = KeyEventResult.ignored;
              for (final ShortcutActivator activator
                  in _keyboardShortcutBindings.keys) {
                if (activator.accepts(event, HardwareKeyboard.instance)) {
                  _keyboardShortcutBindings[activator]!.call(identifier);
                  result = KeyEventResult.handled;
                }
              }
              return result;
            },
            child: widget),
      );
    }

    setState(() {
      _overlayList.add(OverlayItem(
        widget: overlay,
        identifier: identifier,
        focusNode: focusNode,
        delegate: delegate,
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    _keyboardShortcutBindings.addAll({
      LogicalKeySet(LogicalKeyboardKey.escape): (identifier) =>
          remove(identifier),
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlays = _overlayList.map((item) {
      Widget widget = item.widget;

      // requestFocus will cause the children weird focus behaviors.
      // item.focusNode.requestFocus();
      if (item.delegate?.asBarrier() ?? false) {
        widget = Container(
          color: style.barrierColor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTapOnBackground,
            child: widget,
          ),
        );
      }
      return widget;
    }).toList();

    List<Widget> children = <Widget>[widget.child];
    Widget? child = _renderBackground(overlays);
    if (child != null) {
      children.add(child);
    }

    // Try to fix there is no overlay for editabletext widget. e.g. TextField.
    // // Check out the TextSelectionOverlay class in text_selection.dart.
    // // ...
    // //  final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    // // assert(
    // //   overlay != null,
    // //   'No Overlay widget exists above $context.\n'
    // //   'Usually the Navigator created by WidgetsApp provides the overlay. Perhaps your '
    // //   'app content was created above the Navigator with the WidgetsApp builder parameter.',
    // // );
    // // ...

    return MaterialApp(
      theme: Theme.of(context),
      debugShowCheckedModeBanner: false,
      home: Stack(children: children..addAll(overlays)),
    );
  }

  void _handleTapOnBackground() => removeAll();

  Widget? _renderBackground(List<Widget> overlays) {
    Widget? child;
    if (overlays.isNotEmpty) {
      child = Container(
        color: style.barrierColor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTapOnBackground,
        ),
      );

      if (style.blur) {
        child = BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: child,
        );
      }
    }
    return child;
  }
}
