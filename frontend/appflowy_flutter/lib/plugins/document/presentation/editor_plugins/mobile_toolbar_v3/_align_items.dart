import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_menu_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_popup_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _left = 'left';
const _center = 'center';
const _right = 'right';

class AlignItems extends StatelessWidget {
  const AlignItems({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final currentAlignItem = _getCurrentAlignItem();
    final alignMenuItems = _getAlignMenuItems();
    return PopupMenu(
      itemLength: alignMenuItems.length,
      onSelected: (index) {
        editorState.alignBlock(alignMenuItems[index].$1);
      },
      menuBuilder: (context, keys, currentIndex) {
        final children = alignMenuItems
            .mapIndexed(
              (index, e) => [
                MenuItem(
                  key: keys[index],
                  isSelected: currentIndex == index,
                  icon: e.$2,
                ),
                if (index != 0 || index != alignMenuItems.length - 1)
                  const HSpace(12),
              ],
            )
            .flattened
            .toList();
        return MenuWrapper(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
      builder: (context, key) => MobileToolbarItemWrapper(
        key: key,
        size: const Size(82, 52),
        onTap: () async {
          await editorState.alignBlock(currentAlignItem.$1);
        },
        icon: currentAlignItem.$2,
        isSelected: false,
        iconPadding: const EdgeInsets.symmetric(
          vertical: 14.0,
        ),
        showDownArrow: true,
        backgroundColor: const Color(0xFFF2F2F7),
      ),
    );
  }

  (String, FlowySvgData) _getCurrentAlignItem() {
    final align = _getCurrentBlockAlign();
    if (align == _center) {
      return (_center, FlowySvgs.m_aa_align_center_s);
    } else if (align == _right) {
      return (_right, FlowySvgs.m_aa_align_right_s);
    }
    return (_left, FlowySvgs.m_aa_align_left_s);
  }

  List<(String, FlowySvgData)> _getAlignMenuItems() {
    final align = _getCurrentBlockAlign();

    if (align == _center) {
      return [
        (_left, FlowySvgs.m_aa_align_left_s),
        (_right, FlowySvgs.m_aa_align_right_s),
      ];
    } else if (align == _right) {
      return [
        (_left, FlowySvgs.m_aa_align_left_s),
        (_center, FlowySvgs.m_aa_align_center_s),
      ];
    }
    return [
      (_center, FlowySvgs.m_aa_align_center_s),
      (_right, FlowySvgs.m_aa_align_right_s),
    ];
  }

  String _getCurrentBlockAlign() {
    final selection = editorState.selection;
    if (selection == null) {
      return _left;
    }
    final nodes = editorState.getNodesInSelection(selection);
    String? alignString;
    for (final node in nodes) {
      final align = node.attributes[blockComponentAlign];
      if (alignString == null) {
        alignString = align;
      } else if (alignString != align) {
        return _left;
      }
    }
    return alignString ?? _left;
  }
}
