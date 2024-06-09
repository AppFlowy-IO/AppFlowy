import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GridShortcuts extends StatelessWidget {
  const GridShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: bindKeys([]),
      child: Actions(
        dispatcher: LoggingActionDispatcher(),
        actions: const {},
        child: child,
      ),
    );
  }
}

Map<ShortcutActivator, Intent> bindKeys(List<LogicalKeyboardKey> keys) {
  return {for (final key in keys) LogicalKeySet(key): KeyboardKeyIdent(key)};
}

class KeyboardKeyIdent extends Intent {
  const KeyboardKeyIdent(this.key);

  final KeyboardKey key;
}

class LoggingActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    // print('Action invoked: $action($intent) from $context');
    super.invokeAction(action, intent, context);

    return null;
  }
}
