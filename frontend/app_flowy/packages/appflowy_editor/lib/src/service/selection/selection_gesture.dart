import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Because the flutter's [DoubleTapGestureRecognizer] will block the [TapGestureRecognizer]
/// for a while. So we need to implement our own GestureDetector.
@immutable
class SelectionGestureDetector extends StatefulWidget {
  const SelectionGestureDetector({
    Key? key,
    this.child,
    this.onTapDown,
    this.onDoubleTapDown,
    this.onTripleTapDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  }) : super(key: key);

  @override
  State<SelectionGestureDetector> createState() =>
      SelectionGestureDetectorState();

  final Widget? child;

  final GestureTapDownCallback? onTapDown;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureTapDownCallback? onTripleTapDown;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
}

class SelectionGestureDetectorState extends State<SelectionGestureDetector> {
  bool _isDoubleTap = false;
  Timer? _doubleTapTimer;
  int _tripleTabCount = 0;
  Timer? _tripleTabTimer;

  final kTripleTapTimeout = const Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (recognizer) {
            recognizer
              ..onStart = widget.onPanStart
              ..onUpdate = widget.onPanUpdate
              ..onEnd = widget.onPanEnd;
          },
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (recognizer) {
            recognizer.onTapDown = _tapDownDelegate;
          },
        ),
      },
      child: widget.child,
    );
  }

  _tapDownDelegate(TapDownDetails tapDownDetails) {
    if (_tripleTabCount == 2) {
      _tripleTabCount = 0;
      _tripleTabTimer?.cancel();
      _tripleTabTimer = null;
      if (widget.onTripleTapDown != null) {
        widget.onTripleTapDown!(tapDownDetails);
      }
    } else if (_isDoubleTap) {
      _isDoubleTap = false;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = null;
      if (widget.onDoubleTapDown != null) {
        widget.onDoubleTapDown!(tapDownDetails);
      }
      _tripleTabCount++;
    } else {
      if (widget.onTapDown != null) {
        widget.onTapDown!(tapDownDetails);
      }

      _isDoubleTap = true;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(kDoubleTapTimeout, () {
        _isDoubleTap = false;
        _doubleTapTimer = null;
      });

      _tripleTabCount = 1;
      _tripleTabTimer?.cancel();
      _tripleTabTimer = Timer(kTripleTapTimeout, () {
        _tripleTabCount = 0;
        _tripleTabTimer = null;
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _tripleTabTimer?.cancel();
    super.dispose();
  }
}
