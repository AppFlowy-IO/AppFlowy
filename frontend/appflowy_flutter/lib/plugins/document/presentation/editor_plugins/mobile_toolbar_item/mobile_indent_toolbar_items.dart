import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final mobileIndentToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, editorState, __) {
    return onlyShowInTextType(editorState)
        ? const Icon(Icons.format_indent_increase_rounded)
        : null;
  },
  actionHandler: (_, editorState) {
    indentCommand.execute(editorState);
  },
);

final mobileOutdentToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, editorState, __) {
    return onlyShowInTextType(editorState)
        ? const Icon(Icons.format_indent_decrease_rounded)
        : null;
  },
  actionHandler: (_, editorState) {
    outdentCommand.execute(editorState);
  },
);
