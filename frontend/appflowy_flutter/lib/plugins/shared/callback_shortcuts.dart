import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AFBindingCallback = bool Function();

class AFCallbackShortcuts extends StatelessWidget {
  const AFCallbackShortcuts({
    super.key,
    required this.bindings,
    required this.child,
  });

  // The bindings for the shortcuts
  //
  // The result of the callback will be used to determine if the event is handled
  final Map<ShortcutActivator, AFBindingCallback> bindings;
  final Widget child;

  bool _applyKeyEventBinding(ShortcutActivator activator, KeyEvent event) {
    if (activator.accepts(event, HardwareKeyboard.instance)) {
      return bindings[activator]?.call() ?? false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        KeyEventResult result = KeyEventResult.ignored;
        for (final ShortcutActivator activator in bindings.keys) {
          result = _applyKeyEventBinding(activator, event)
              ? KeyEventResult.handled
              : result;
        }
        return result;
      },
      child: child,
    );
  }
}
