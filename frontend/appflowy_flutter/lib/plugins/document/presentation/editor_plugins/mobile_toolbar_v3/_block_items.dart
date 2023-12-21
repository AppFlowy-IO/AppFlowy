import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/util.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class BlockItems extends StatelessWidget {
  BlockItems({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  final List<(FlowySvgData, String)> _blockItems = [
    (FlowySvgs.m_aa_bulleted_list_s, BulletedListBlockKeys.type),
    (FlowySvgs.m_aa_numbered_list_s, NumberedListBlockKeys.type),
    (FlowySvgs.m_aa_quote_s, QuoteBlockKeys.type),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._blockItems
              .mapIndexed(
                (index, e) => [
                  _buildBlockItem(
                    index,
                    e.$1,
                    e.$2,
                  ),
                  if (index != 0) const ScaledVerticalDivider(),
                ],
              )
              .flattened,
          // this item is a special case, use link item here instead of block item

          _buildLinkItem(),
        ],
      ),
    );
  }

  Widget _buildBlockItem(
    int index,
    FlowySvgData icon,
    String blockType,
  ) {
    return MobileToolbarItemWrapper(
      size: const Size(62, 54),
      enableTopLeftRadius: index == 0,
      enableBottomLeftRadius: index == 0,
      enableTopRightRadius: false,
      enableBottomRightRadius: false,
      onTap: () async {
        await editorState.convertBlockType(blockType);
      },
      backgroundColor: const Color(0xFFF2F2F7),
      icon: icon,
      isSelected: editorState.isBlockTypeSelected(blockType),
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
    );
  }

  Widget _buildLinkItem() {
    return MobileToolbarItemWrapper(
      size: const Size(62, 54),
      enableTopLeftRadius: false,
      enableBottomLeftRadius: false,
      enableTopRightRadius: true,
      enableBottomRightRadius: true,
      showDownArrow: true,
      onTap: () {},
      backgroundColor: const Color(0xFFF2F2F7),
      icon: FlowySvgs.m_aa_link_s,
      isSelected: false,
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
    );
  }
}
