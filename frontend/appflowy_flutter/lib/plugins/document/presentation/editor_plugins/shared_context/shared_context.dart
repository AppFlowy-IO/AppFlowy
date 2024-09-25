import 'package:flutter/widgets.dart';

/// Shared context for the editor plugins.
///
/// For example, the backspace command requires the focus node of the cover title.
/// so we need to use the shared context to get the focus node.
class SharedEditorContext {
  SharedEditorContext();

  // The focus node of the cover title.
  // It's null when the cover title is not focused.
  FocusNode? coverTitleFocusNode;
}
