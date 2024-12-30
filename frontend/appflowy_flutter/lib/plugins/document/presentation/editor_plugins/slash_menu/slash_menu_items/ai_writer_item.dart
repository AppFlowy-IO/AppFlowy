import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
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

// auto generate menu item
SelectionMenuItem aiWriterSlashMenuItem = SelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_aiWriter.tr,
  keywords: _keywords,
  handler: (editorState, _, __) async => editorState.insertAiWriter(),
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_ai_writer_s,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
);

extension on EditorState {
  Future<void> insertAiWriter() async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final newNode = aiWriterNode(start: selection);

    final transaction = this.transaction;
    //default insert after
    final path = node.path.next;
    transaction
      ..insertNode(path, newNode)
      ..afterSelection = null;
    await apply(
      transaction,
      options: const ApplyOptions(inMemoryUpdate: true),
    );
  }
}
