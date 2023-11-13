import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

final mobileBlocksToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (_, __) =>
      const AFMobileIcon(afMobileIcons: AFMobileIcons.list),
  itemMenuBuilder: (editorState, selection, _) {
    return _MobileListMenu(
      editorState: editorState,
      selection: selection,
    );
  },
);

class _MobileListMenu extends StatelessWidget {
  const _MobileListMenu({
    required this.editorState,
    required this.selection,
  });

  final Selection selection;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 5,
      shrinkWrap: true,
      children: [
        // bulleted list, numbered list
        _buildListButton(
          context,
          BulletedListBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.bulletedList),
          LocaleKeys.document_plugins_bulletedList.tr(),
        ),
        _buildListButton(
          context,
          NumberedListBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.numberedList),
          LocaleKeys.document_plugins_numberedList.tr(),
        ),

        // todo list, quote list
        _buildListButton(
          context,
          TodoListBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.checkbox),
          LocaleKeys.document_plugins_todoList.tr(),
        ),
        _buildListButton(
          context,
          QuoteBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.quote),
          LocaleKeys.document_plugins_quoteList.tr(),
        ),

        // toggle list, callout
        _buildListButton(
          context,
          ToggleListBlockKeys.type,
          const FlowySvg(
            FlowySvgs.toggle_list_s,
            size: Size.square(24),
          ),
          LocaleKeys.document_plugins_toggleList.tr(),
        ),
        _buildListButton(
          context,
          CalloutBlockKeys.type,
          const Icon(Icons.note_rounded),
          LocaleKeys.document_plugins_callout.tr(),
        ),
      ],
    );
  }

  Widget _buildListButton(
    BuildContext context,
    String listBlockType,
    Widget icon,
    String label,
  ) {
    final node = editorState.getNodeAtPath(selection.start.path);
    final type = node?.type;
    if (node == null || type == null) {
      const SizedBox.shrink();
    }
    final isSelected = type == listBlockType;
    return MobileToolbarItemMenuBtn(
      icon: icon,
      label: FlowyText(label),
      isSelected: isSelected,
      onPressed: () async {
        await editorState.formatNode(
          selection,
          (node) {
            final attributes = {
              ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
              if (listBlockType == TodoListBlockKeys.type)
                TodoListBlockKeys.checked: false,
              if (listBlockType == CalloutBlockKeys.type)
                CalloutBlockKeys.icon: '📌',
            };
            return node.copyWith(
              type: isSelected ? ParagraphBlockKeys.type : listBlockType,
              attributes: attributes,
            );
          },
        );
      },
    );
  }
}
