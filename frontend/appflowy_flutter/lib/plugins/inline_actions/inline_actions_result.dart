import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

typedef SelectItemHandler = void Function(
  BuildContext context,
  EditorState editorState,
  InlineActionsMenuService menuService,
  (int start, int end) replacement,
);

class InlineActionsMenuItem {
  InlineActionsMenuItem({
    required this.label,
    this.icon,
    this.keywords,
    this.onSelected,
  });

  final String label;
  final Widget Function(bool onSelected)? icon;
  final List<String>? keywords;
  final SelectItemHandler? onSelected;
}

class InlineActionsResult {
  InlineActionsResult({
    this.title,
    required this.results,
    this.startsWithKeywords,
  });

  /// Localized title to be displayed above the results
  /// of the current group.
  ///
  /// If null, no title will be displayed.
  ///
  final String? title;

  /// List of results that will be displayed for this group
  /// made up of [SelectionMenuItem]s.
  ///
  final List<InlineActionsMenuItem> results;

  /// If the search term start with one of these keyword,
  /// the results will be reordered such that these results
  /// will be above.
  ///
  final List<String>? startsWithKeywords;
}
