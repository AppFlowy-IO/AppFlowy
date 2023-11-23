import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class BlockMenuItem {
  const BlockMenuItem({
    required this.blockType,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected,
  });

  // block type
  final String blockType;
  final Widget icon;
  final String label;
  // callback
  final void Function(
    EditorState editorState,
    Selection selection,
    // used to control the open or close the menu
    MobileToolbarWidgetService service,
  ) onTap;

  final bool Function(
    EditorState editorState,
    Selection selection,
  )? isSelected;
}

class BlocksMenu extends StatelessWidget {
  const BlocksMenu({
    super.key,
    required this.editorState,
    required this.items,
    required this.service,
  });

  final EditorState editorState;
  final List<BlockMenuItem> items;
  final MobileToolbarWidgetService service;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 4,
      padding: const EdgeInsets.only(
        bottom: 36.0,
      ),
      shrinkWrap: true,
      children: items.map((item) {
        final selection = editorState.selection;
        if (selection == null) {
          return const SizedBox.shrink();
        }
        bool isSelected = false;
        if (item.isSelected != null) {
          isSelected = item.isSelected!(editorState, selection);
        } else {
          isSelected = _isSelected(editorState, selection, item.blockType);
        }
        return MobileToolbarItemMenuBtn(
          icon: item.icon,
          label: FlowyText(item.label),
          isSelected: isSelected,
          onPressed: () async {
            item.onTap(editorState, selection, service);
          },
        );
      }).toList(),
    );
  }

  bool _isSelected(
    EditorState editorState,
    Selection selection,
    String blockType,
  ) {
    final node = editorState.getNodeAtPath(selection.start.path);
    final type = node?.type;
    if (node == null || type == null) {
      return false;
    }
    return type == blockType;
  }
}
