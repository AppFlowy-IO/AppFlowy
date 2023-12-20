import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
          _HeadingsAndText(
            editorState: editorState,
          ),
          const _ScaledVSpace(),
          _BIUSItems(
            editorState: editorState,
          ),
          const _ScaledVSpace(),
          Row(
            children: [
              _BlockItems(
                editorState: editorState,
              ),
              const Spacer(),
              const _AlignItems(),
            ],
          ),
          const _ScaledVSpace(),
          const Row(
            children: [
              _FontFamilyItem(),
              Spacer(),
              _IndentAndOutdentItems(),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeadingsAndText extends StatelessWidget {
  const _HeadingsAndText({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _HeadingOrTextItem(
          icon: FlowySvgs.h1_s,
          blockType: HeadingBlockKeys.type,
          editorState: editorState,
          level: 1,
        ),
        _HeadingOrTextItem(
          icon: FlowySvgs.h2_s,
          blockType: HeadingBlockKeys.type,
          editorState: editorState,
          level: 2,
        ),
        _HeadingOrTextItem(
          icon: FlowySvgs.h3_s,
          blockType: HeadingBlockKeys.type,
          editorState: editorState,
          level: 3,
        ),
        _HeadingOrTextItem(
          icon: FlowySvgs.text_s,
          blockType: ParagraphBlockKeys.type,
          editorState: editorState,
        ),
      ],
    );
  }
}

class _HeadingOrTextItem extends StatefulWidget {
  const _HeadingOrTextItem({
    required this.icon,
    required this.blockType,
    required this.editorState,
    this.level,
  });

  final FlowySvgData icon;
  final String blockType;
  final EditorState editorState;
  final int? level;

  @override
  State<_HeadingOrTextItem> createState() => _HeadingOrTextItemState();
}

class _HeadingOrTextItemState extends State<_HeadingOrTextItem> {
  bool isSelected = false;

  @override
  void initState() {
    super.initState();

    isSelected = _isBlockTypeSelected(
      widget.editorState,
      widget.blockType,
      level: widget.level,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Item(
      size: const Size(76, 52),
      onTap: () {},
      icon: widget.icon,
      isSelected: isSelected,
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
    );
  }
}

class _BIUSItems extends StatelessWidget {
  _BIUSItems({
    required this.editorState,
  });

  final EditorState editorState;

  final List<(FlowySvgData, String)> _bius = [
    (FlowySvgs.m_aa_bold_s, AppFlowyRichTextKeys.bold),
    (FlowySvgs.m_aa_italic_s, AppFlowyRichTextKeys.italic),
    (FlowySvgs.m_aa_underline_s, AppFlowyRichTextKeys.underline),
    (FlowySvgs.m_aa_strike_s, AppFlowyRichTextKeys.strikethrough),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._bius
              .mapIndexed(
                (index, e) => [
                  _buildBIUSItem(
                    index,
                    e.$1,
                    e.$2,
                  ),
                  if (index != 0 || index != _bius.length - 1)
                    const _VerticalDivider(),
                ],
              )
              .flattened,
        ],
      ),
    );
  }

  Widget _buildBIUSItem(
    int index,
    FlowySvgData icon,
    String richTextKey,
  ) {
    return _Item(
      size: const Size(62, 52),
      enableTopLeftRadius: index == 0,
      enableBottomLeftRadius: index == 0,
      enableTopRightRadius: index == _bius.length - 1,
      enableBottomRightRadius: index == _bius.length - 1,
      color: const Color(0xFFF2F2F7),
      onTap: () {},
      icon: icon,
      isSelected: _isTextDecorationSelected(editorState, richTextKey),
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
    );
  }
}

class _BlockItems extends StatelessWidget {
  _BlockItems({
    required this.editorState,
  });

  final EditorState editorState;

  final List<(FlowySvgData, String)> _blockItems = [
    (FlowySvgs.m_aa_bulleted_list_s, BulletedListBlockKeys.type),
    (FlowySvgs.m_aa_numbered_list_s, NumberedListBlockKeys.type),
    (FlowySvgs.m_aa_quote_s, QuoteBlockKeys.type),
    (FlowySvgs.m_aa_link_s, ToggleListBlockKeys.type),
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
                  if (index != 0 || index != _blockItems.length - 1)
                    const _VerticalDivider(),
                ],
              )
              .flattened,
        ],
      ),
    );
  }

  Widget _buildBlockItem(
    int index,
    FlowySvgData icon,
    String blockType,
  ) {
    return _Item(
      size: const Size(62, 54),
      enableTopLeftRadius: index == 0,
      enableBottomLeftRadius: index == 0,
      enableTopRightRadius: index == _blockItems.length - 1,
      enableBottomRightRadius: index == _blockItems.length - 1,
      showDownArrow: index == _blockItems.length - 1,
      onTap: () {},
      color: const Color(0xFFF2F2F7),
      icon: icon,
      isSelected: _isBlockTypeSelected(editorState, blockType),
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
    );
  }
}

class _FontFamilyItem extends StatelessWidget {
  const _FontFamilyItem();

  @override
  Widget build(BuildContext context) {
    return _Item(
      size: const Size(144, 52),
      onTap: () {},
      text: 'Sans Serif',
      color: const Color(0xFFF2F2F7),
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

class _IndentAndOutdentItems extends StatelessWidget {
  const _IndentAndOutdentItems();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          _Item(
            size: const Size(95, 52),
            onTap: () {},
            icon: FlowySvgs.m_aa_outdent_s,
            isSelected: false,
            enableTopRightRadius: false,
            enableBottomRightRadius: false,
            iconPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
            ),
            color: const Color(0xFFF2F2F7),
          ),
          const _VerticalDivider(),
          _Item(
            size: const Size(95, 52),
            onTap: () {},
            icon: FlowySvgs.m_aa_indent_s,
            isSelected: false,
            enableTopLeftRadius: false,
            enableBottomLeftRadius: false,
            iconPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
            ),
            color: const Color(0xFFF2F2F7),
          ),
        ],
      ),
    );
  }
}

class _AlignItems extends StatelessWidget {
  const _AlignItems();

  @override
  Widget build(BuildContext context) {
    return _Item(
      size: const Size(82, 52),
      onTap: () {},
      icon: FlowySvgs.m_aa_align_left_s,
      isSelected: false,
      iconPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
      ),
      showDownArrow: true,
      color: const Color(0xFFF2F2F7),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.size,
    required this.onTap,
    this.icon,
    this.text,
    this.color,
    required this.isSelected,
    required this.iconPadding,
    this.enableBottomLeftRadius = true,
    this.enableBottomRightRadius = true,
    this.enableTopLeftRadius = true,
    this.enableTopRightRadius = true,
    this.showDownArrow = false,
    this.showRightArrow = false,
    this.textPadding = EdgeInsets.zero,
  });

  final Size size;
  final VoidCallback onTap;
  final FlowySvgData? icon;
  final String? text;
  final bool isSelected;
  final EdgeInsets iconPadding;
  final bool enableTopLeftRadius;
  final bool enableTopRightRadius;
  final bool enableBottomRightRadius;
  final bool enableBottomLeftRadius;
  final bool showDownArrow;
  final bool showRightArrow;
  final Color? color;
  final EdgeInsets textPadding;

  @override
  Widget build(BuildContext context) {
    // the ui design is based on 375.0 width
    final scale = context.scale;
    final radius = Radius.circular(12 * scale);
    final Widget child;
    if (icon != null) {
      child = FlowySvg(
        icon!,
        color: isSelected ? Colors.white : Colors.black,
      );
    } else if (text != null) {
      child = Padding(
        padding: textPadding * scale,
        child: FlowyText(
          text!,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      throw ArgumentError('icon and text cannot be null at the same time');
    }

    return GestureDetector(
      onTap: () {},
      child: Stack(
        children: [
          Container(
            height: size.height * scale,
            width: size.width * scale,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00BCF0) : color,
              borderRadius: BorderRadius.only(
                topLeft: enableTopLeftRadius ? radius : Radius.zero,
                topRight: enableTopRightRadius ? radius : Radius.zero,
                bottomRight: enableBottomRightRadius ? radius : Radius.zero,
                bottomLeft: enableBottomLeftRadius ? radius : Radius.zero,
              ),
            ),
            padding: iconPadding * scale,
            child: child,
          ),
          if (showDownArrow)
            Positioned(
              right: 9.0 * scale,
              bottom: 9.0 * scale,
              child: const FlowySvg(FlowySvgs.m_aa_down_arrow_s),
            ),
          if (showRightArrow)
            Positioned.fill(
              right: 12.0 * scale,
              child: const Align(
                alignment: Alignment.centerRight,
                child: FlowySvg(FlowySvgs.m_aa_arrow_right_s),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return HSpace(
      1.5 * context.scale,
    );
  }
}

class _ScaledVSpace extends StatelessWidget {
  const _ScaledVSpace();

  @override
  Widget build(BuildContext context) {
    return VSpace(12.0 * context.scale);
  }
}

bool _isBlockTypeSelected(
  EditorState editorState,
  String blockType, {
  int? level,
}) {
  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.start.path);
  final type = node?.type;
  if (node == null || type == null) {
    return false;
  }
  if (level != null && blockType == HeadingBlockKeys.type) {
    return type == blockType &&
        node.attributes[HeadingBlockKeys.level] == level;
  }
  return type == blockType;
}

bool _isTextDecorationSelected(
  EditorState editorState,
  String richTextKey,
) {
  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }

  final nodes = editorState.getNodesInSelection(selection);
  bool isSelected;
  if (selection.isCollapsed) {
    isSelected = editorState.toggledStyle.containsKey(
      richTextKey,
    );
    if (isSelected) {
      return true;
    }
    if (selection.startIndex != 0) {
      // get previous index text style
      isSelected = nodes.allSatisfyInSelection(
          selection.copyWith(
            start: selection.start.copyWith(
              offset: selection.startIndex - 1,
            ),
          ), (delta) {
        return delta.everyAttributes(
          (attributes) => attributes[richTextKey] == true,
        );
      });
    }
  } else {
    isSelected = nodes.allSatisfyInSelection(selection, (delta) {
      return delta.everyAttributes(
        (attributes) => attributes[richTextKey] == true,
      );
    });
  }
  return isSelected;
}

extension on BuildContext {
  double get scale => MediaQuery.of(this).size.width / 375.0;
}
