import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

typedef SelectItemHandler = void Function(
  BuildContext context,
  EditorState editorState,
  InlineActionsMenuService menuService,
);

class InlineActionsMenuItem {
  InlineActionsMenuItem({
    required this.label,
    this.icon,
    this.keywords,
    this.onSelected,
    this.startKeyword,
  });

  final Widget label;
  final Widget Function(bool onSelected)? icon;
  final List<String>? keywords;
  final SelectItemHandler? onSelected;
  final String? startKeyword;
}

class InlineActionsResult {
  InlineActionsResult({
    required this.title,
    required this.results,
  });

  /// Localized title to be displayed above the results
  /// of the current group.
  ///
  final String title;

  /// TODO(Xazin): Enable display order priority by keywords
  ///  List of keywords, which can be localized, that if present
  ///  in the search string, will prioritize this group in
  ///  display order.
  ///
  // final List<String> keywords;

  /// List of results that will be displayed for this group
  /// made up of [SelectionMenuItem]s.
  ///
  final List<InlineActionsMenuItem> results;
}
