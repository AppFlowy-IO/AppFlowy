import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/slash_menu/slash_menu_items/slash_menu_item_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final _keywords = [
  'insert date',
  'date',
  'time',
  'reminder',
  'schedule',
];

// date or reminder menu item
SelectionMenuItem dateOrReminderSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_dateOrReminder.tr(),
  keywords: _keywords,
  handler: (editorState, _, __) async => editorState.insertDateReference(),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_date_or_reminder_s,
    isSelected: isSelected,
    style: style,
  ),
);

extension on EditorState {
  Future<void> insertDateReference() async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    final transaction = this.transaction
      ..replaceText(
        node,
        selection.start.offset,
        0,
        MentionBlockKeys.mentionChar,
        attributes: {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.date.name,
            MentionBlockKeys.date: DateTime.now().toIso8601String(),
          },
        },
      );

    await apply(transaction);
  }
}
