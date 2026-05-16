import 'dart:async';

import 'package:flowy_infra_ui_platform_interface/flowy_infra_ui_platform_interface.dart';
import 'package:flutter/material.dart';

class KeyboardVisibilityDetector extends StatefulWidget {
  const KeyboardVisibilityDetector({
    super.key,
    required this.child,
    this.onKeyboardVisibilityChange,
  });

  final Widget child;
  final void Function(bool)? onKeyboardVisibilityChange;

  @override
  State<KeyboardVisibilityDetector> createState() =>
      _KeyboardVisibilityDetectorState();
}

class _KeyboardVisibilityDetectorState
    extends State<KeyboardVisibilityDetector> {
  FlowyInfraUIPlatform get _platform => FlowyInfraUIPlatform.instance;

  bool isObserving = false;
  bool isKeyboardVisible = false;
  late StreamSubscription _keyboardSubscription;

  @override
  void initState() {
    super.initState();
    _keyboardSubscription =
        _platform.onKeyboardVisibilityChange.listen((newValue) {
      setState(() {
        isKeyboardVisible = newValue;
        if (widget.onKeyboardVisibilityChange != null) {
          widget.onKeyboardVisibilityChange!(newValue);
        }
      });
    });
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _KeyboardVisibilityDetectorInheritedWidget(
      isKeyboardVisible: isKeyboardVisible,
      child: widget.child,
    );
  }
}

class _KeyboardVisibilityDetectorInheritedWidget extends InheritedWidget {
  const _KeyboardVisibilityDetectorInheritedWidget({
    required this.isKeyboardVisible,
    required super.child,
  });

  final bool isKeyboardVisible;

  @override
  bool updateShouldNotify(
      _KeyboardVisibilityDetectorInheritedWidget oldWidget) {
    return isKeyboardVisible != oldWidget.isKeyboardVisible;
  }
}
