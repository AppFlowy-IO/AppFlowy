import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

class TextBlockShortcuts extends StatefulWidget {
  const TextBlockShortcuts({
    super.key,
    this.focusNode,
    required this.textBlockState,
    required this.shortcuts,
    required this.child,
  });

  final FocusNode? focusNode;
  final TextBlockState textBlockState;
  final List<ShortcutEvent> shortcuts;
  final Widget child;

  @override
  State<TextBlockShortcuts> createState() => _TextBlockShortcutsState();
}

class _TextBlockShortcutsState extends State<TextBlockShortcuts> {
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _effectiveFocusNode,
      onKey: _onKey,
      onFocusChange: (value) {
        Log.keyboard.debug('block shortcut service focus change $value');
      },
      child: widget.child,
    );
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    Log.keyboard.debug('block shortcut service $event');

    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    for (final shortcutEvent in widget.shortcuts) {
      if (shortcutEvent.canRespondToRawKeyEvent(event)) {
        final result = shortcutEvent.blockShortcutHandler
            ?.call(context, widget.textBlockState);
        if (result == KeyEventResult.handled) {
          return KeyEventResult.handled;
        } else if (result == KeyEventResult.skipRemainingHandlers) {
          return KeyEventResult.skipRemainingHandlers;
        }
        continue;
      }
    }

    return KeyEventResult.ignored;
  }
}

extension on ShortcutEvent {
  bool canRespondToRawKeyEvent(RawKeyEvent event) {
    return ((character?.isNotEmpty ?? false) && character == event.character) ||
        keybindings.containsKeyEvent(event);
  }
}
