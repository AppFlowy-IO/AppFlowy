import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AFCallbackShortcutsProvider {
  final ValueNotifier<bool> isShortcutsEnabled = ValueNotifier(true);
}

class AFCallbackShortcuts extends StatelessWidget {
  const AFCallbackShortcuts({
    super.key,
    required this.bindings,
    required this.canAcceptEvent,
    required this.child,
  });

  final Map<ShortcutActivator, VoidCallback> bindings;
  final bool Function(FocusNode node, KeyEvent event) canAcceptEvent;
  final Widget child;

  bool _applyKeyEventBinding(ShortcutActivator activator, KeyEvent event) {
    if (activator.accepts(event, HardwareKeyboard.instance)) {
      bindings[activator]!.call();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (!canAcceptEvent(node, event)) {
          return KeyEventResult.ignored;
        }
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
