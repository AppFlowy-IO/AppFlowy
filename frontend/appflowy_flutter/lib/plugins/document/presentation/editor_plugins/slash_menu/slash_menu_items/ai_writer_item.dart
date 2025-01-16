import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/operations/ai_writer_entities.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

import 'slash_menu_item_builder.dart';

final _keywords = [
  'ai',
  'openai',
  'writer',
  'ai writer',
  'autogenerator',
];

SelectionMenuItem aiWriterSlashMenuItem = SelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_aiWriter.tr,
  keywords: [
    ..._keywords,
    LocaleKeys.document_slashMenu_name_aiWriter.tr(),
  ],
  handler: (editorState, _, __) async =>
      _insertAiWriter(editorState, AiWriterCommand.userQuestion),
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: AiWriterCommand.userQuestion.icon,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
);

Future<void> _insertAiWriter(
  EditorState editorState,
  AiWriterCommand action,
) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.delta == null) {
    return;
  }
  final newNode = aiWriterNode(
    selection: selection,
    command: action,
  );

  // default insert after
  final path = node.path.next;
  final transaction = editorState.transaction
    ..insertNode(path, newNode)
    ..afterSelection = null;

  await editorState.apply(
    transaction,
    options: const ApplyOptions(
      recordUndo: false,
      inMemoryUpdate: true,
    ),
  );
}
