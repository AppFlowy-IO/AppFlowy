import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

SelectionMenuItem dateMenuItem = SelectionMenuItem(
  getName: LocaleKeys.document_plugins_insertDate.tr,
  icon: (_, isSelected, style) => FlowySvg(
    FlowySvgs.date_s,
    color: isSelected
        ? style.selectionMenuItemSelectedIconColor
        : style.selectionMenuItemIconColor,
  ),
  keywords: ['insert date', 'date', 'time'],
  handler: (editorState, menuService, context) =>
      insertDateReference(editorState),
);

Future<void> insertDateReference(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null) {
    return;
  }

  final transaction = editorState.transaction
    ..replaceText(
      node,
      selection.start.offset,
      0,
      '\$',
      attributes: {
        MentionBlockKeys.mention: {
          MentionBlockKeys.type: MentionType.date.name,
          MentionBlockKeys.date: DateTime.now().toIso8601String(),
        },
      },
    );

  await editorState.apply(transaction);
}
