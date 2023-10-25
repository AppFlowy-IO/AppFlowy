import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

SelectionMenuItem dateMenuItem = SelectionMenuItem(
  name: 'Insert Date',
  icon: (_, isSelected, style) => FlowySvg(
    FlowySvgs.date_s,
    color: isSelected
        ? style.selectionMenuItemSelectedIconColor
        : style.selectionMenuItemIconColor,
  ),
  keywords: ['insert date', 'date', 'time'],
  handler: (editorState, menuService, context) =>
      _insertDateReference(editorState),
);

Future<void> _insertDateReference(EditorState editorState) async {
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
        }
      },
    );

  await editorState.apply(transaction);
}
