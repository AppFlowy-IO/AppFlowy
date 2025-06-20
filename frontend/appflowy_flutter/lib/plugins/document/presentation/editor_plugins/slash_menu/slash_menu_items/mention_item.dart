import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/slash_menu/slash_menu_items/slash_menu_item_builder.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final _keywords = [
  'mention',
  'person',
];

// mention a person item
SelectionMenuItem mentionSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_mentionMenu_mentionAPerson.tr(),
  keywords: _keywords,
  handler: (editorState, _, __) async => editorState.insertAtCharacter(),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.mention_invite_user_m,
    isSelected: isSelected,
    style: style,
  ),
);

extension on EditorState {
  Future<void> insertAtCharacter() async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final context = service.scrollServiceKey.currentContext;
    if (context == null || !context.mounted) return;

    await inlineActionsCommandHandler(this, context);
  }
}
