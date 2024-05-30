import 'package:flutter/material.dart';

class AFFocusManager extends InheritedWidget {
  AFFocusManager({super.key, required super.child});

  final loseFocusNotifier = ShouldLoseFocus();

  void notifyLoseFocus() {
    loseFocusNotifier.notify();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static AFFocusManager of(BuildContext context) {
    final AFFocusManager? result =
        context.dependOnInheritedWidgetOfExactType<AFFocusManager>();

    assert(result != null, "AFFocusManager could not be found");
    return result!;
  }
}

class ShouldLoseFocus with ChangeNotifier {
  /// Should not be accessed directly, use the [AFFocusManager]
  /// for clearer usage.
  ///
  /// Example: `AFFocusManager.of(context).notifyLoseFocus();`
  ///
  void notify() => notifyListeners();
}
