import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final mobileIndentToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, editorState) {
    return onlyShowInTextType(editorState)
        ? const Icon(Icons.format_indent_increase_rounded)
        : null;
  },
  actionHandler: (editorState, selection) {
    indentCommand.execute(editorState);
  },
);

final mobileOutdentToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, editorState) {
    return onlyShowInTextType(editorState)
        ? const Icon(Icons.format_indent_decrease_rounded)
        : null;
  },
  actionHandler: (editorState, selection) {
    outdentCommand.execute(editorState);
  },
);
