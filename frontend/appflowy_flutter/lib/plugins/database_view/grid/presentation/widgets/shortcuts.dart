import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GridShortcuts extends StatelessWidget {
  final Widget child;
  const GridShortcuts({required this.child, Key? key}) : super(key: key);

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
  return {for (var key in keys) LogicalKeySet(key): KeyboardKeyIdent(key)};
}

Map<Type, Action<Intent>> bindActions() {
  return {
    KeyboardKeyIdent: KeyboardBindingAction(),
  };
}

class KeyboardKeyIdent extends Intent {
  final KeyboardKey key;

  const KeyboardKeyIdent(this.key);
}

class KeyboardBindingAction extends Action<KeyboardKeyIdent> {
  KeyboardBindingAction();

  @override
  void invoke(covariant KeyboardKeyIdent intent) {
    // print(intent);
  }
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
