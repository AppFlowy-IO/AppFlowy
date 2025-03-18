import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/ai_writer_toolbar_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const placeholderItemId = 'editor.placeholder';
const paddingPlaceholderItemId = 'editor.padding_placeholder';

final ToolbarItem customPlaceholderItem = ToolbarItem(
  id: placeholderItemId,
  group: -1,
  isActive: (editorState) => true,
  builder: (context, __, ___, ____, _____) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Container(
        width: 1,
        color: Color(0xffE8ECF3).withAlpha(isDark ? 40 : 255),
      ),
    );
  },
);

ToolbarItem buildPaddingPlaceholderItem(
  int group, {
  bool Function(EditorState editorState)? isActive,
}) =>
    ToolbarItem(
      id: paddingPlaceholderItemId,
      group: group,
      isActive: isActive,
      builder: (context, __, ___, ____, _____) => HSpace(4),
    );

ToolbarItem group0PaddingItem = buildPaddingPlaceholderItem(
  0,
  isActive: onlyShowInTextTypeAndExcludeTable,
);

ToolbarItem group1PaddingItem =
    buildPaddingPlaceholderItem(1, isActive: showInAnyTextType);

ToolbarItem group4PaddingItem = buildPaddingPlaceholderItem(
  4,
  isActive: onlyShowInSingleSelectionAndTextType,
);
