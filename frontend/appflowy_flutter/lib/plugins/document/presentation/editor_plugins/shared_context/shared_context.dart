import 'package:flutter/widgets.dart';

/// Shared context for the editor plugins.
///
/// For example, the backspace command requires the focus node of the cover title.
/// so we need to use the shared context to get the focus node.
///
class SharedEditorContext {
  SharedEditorContext() : _coverTitleFocusNode = FocusNode();

  // The focus node of the cover title.
  final FocusNode _coverTitleFocusNode;

  FocusNode get coverTitleFocusNode => _coverTitleFocusNode;

  void dispose() {
    _coverTitleFocusNode.dispose();
  }
}
