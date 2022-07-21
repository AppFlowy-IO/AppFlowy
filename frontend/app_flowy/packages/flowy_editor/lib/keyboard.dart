import '../render/selectable.dart';
import 'editor_state.dart';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class Keyboard extends StatelessWidget {
  final Widget child;
  final focusNode = FocusNode();
  final EditorState editorState;

  Keyboard({
    Key? key,
    required this.child,
    required this.editorState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKey: _onKey,
      child: child,
    );
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }
    List<KeyEventResult> result = [];
    for (final node in editorState.selectedNodes) {
      if (node.key != null &&
          node.key?.currentState is KeyboardEventsRespondable) {
        final respondable = node.key!.currentState as KeyboardEventsRespondable;
        result.add(respondable.onKeyDown(event));
      }
    }
    if (result.contains(KeyEventResult.handled)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
