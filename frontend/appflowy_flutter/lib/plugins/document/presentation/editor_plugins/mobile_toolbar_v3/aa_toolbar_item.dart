import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_align_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_bius_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_block_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_color_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_heading_and_text_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_indent_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final appflowyTextDecorationItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, onMenu, _) {
    return AppFlowyMobileToolbarIconItem(
      keepSelectedStatus: true,
      icon: FlowySvgs.m_text_decoration_m,
      onTap: () => onMenu?.call(),
    );
  },
  menuBuilder: (context, editorState, service) {
    final selection = editorState.selection;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    return _TextDecorationMenu(
      editorState,
      selection,
      service,
    );
  },
);

class _TextDecorationMenu extends StatefulWidget {
  const _TextDecorationMenu(
    this.editorState,
    this.selection,
    this.service,
  );

  final EditorState editorState;
  final Selection selection;
  final MobileToolbarWidgetService service;

  @override
  State<_TextDecorationMenu> createState() => _TextDecorationMenuState();
}

class _TextDecorationMenuState extends State<_TextDecorationMenu> {
  EditorState get editorState => widget.editorState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
            top: 24,
            bottom: 20,
            left: 12,
            right: 12,
          ) *
          context.scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeadingsAndTextItems(
            editorState: editorState,
          ),
          const ScaledVSpace(),
          Row(
            children: [
              BIUSItems(
                editorState: editorState,
              ),
              const Spacer(),
              const ColorItem(),
            ],
          ),
          const ScaledVSpace(),
          Row(
            children: [
              BlockItems(
                editorState: editorState,
              ),
              const Spacer(),
              AlignItems(
                editorState: editorState,
              ),
            ],
          ),
          const ScaledVSpace(),
          Row(
            children: [
              const _FontFamilyItem(),
              const Spacer(),
              IndentAndOutdentItems(
                editorState: editorState,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FontFamilyItem extends StatelessWidget {
  const _FontFamilyItem();

  @override
  Widget build(BuildContext context) {
    return MobileToolbarItemWrapper(
      size: const Size(144, 52),
      onTap: () {},
      text: 'Sans Serif',
      backgroundColor: const Color(0xFFF2F2F7),
      isSelected: false,
      showRightArrow: true,
      iconPadding: const EdgeInsets.only(
        top: 14.0,
        bottom: 14.0,
        left: 14.0,
        right: 12.0,
      ),
      textPadding: const EdgeInsets.only(
        right: 16.0,
      ),
    );
  }
}
