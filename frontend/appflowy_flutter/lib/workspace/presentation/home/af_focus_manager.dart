import 'package:flutter/material.dart';

/// Simple ChangeNotifier that can be listened to, notifies the
/// application on events that should trigger focus loss.
///
/// Eg. lose focus in AppFlowyEditor
///
abstract class ShouldLoseFocus with ChangeNotifier {}

/// Private implementation to allow the [AFFocusManager] to
/// call [notifyListeners] without being directly invokable.
///
class _ShouldLoseFocusImpl extends ShouldLoseFocus {
  void notify() => notifyListeners();
}

class AFFocusManager extends InheritedWidget {
  AFFocusManager({super.key, required super.child});

  final ShouldLoseFocus loseFocusNotifier = _ShouldLoseFocusImpl();

  void notifyLoseFocus() {
    (loseFocusNotifier as _ShouldLoseFocusImpl).notify();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static AFFocusManager of(BuildContext context) {
    final AFFocusManager? result =
        context.dependOnInheritedWidgetOfExactType<AFFocusManager>();

    assert(result != null, "AFFocusManager could not be found");
    return result!;
  }

  static AFFocusManager? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AFFocusManager>();
  }
}
