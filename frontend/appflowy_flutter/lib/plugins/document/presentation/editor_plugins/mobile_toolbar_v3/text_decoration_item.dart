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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeadingsAndText(
            editorState: editorState,
          ),
          const VSpace(12.0),
          _BIUSItems(
            editorState: editorState,
          ),
          const VSpace(12.0),
          _BlockItems(
            editorState: editorState,
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
      size: const Size(76, 54),
      onTap: () {},
      icon: widget.icon,
      isSelected: isSelected,
      iconPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
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
    (FlowySvgs.bold_s, AppFlowyRichTextKeys.bold),
    (FlowySvgs.italic_s, AppFlowyRichTextKeys.italic),
    (FlowySvgs.underline_s, AppFlowyRichTextKeys.underline),
    (FlowySvgs.strikethrough_s, AppFlowyRichTextKeys.strikethrough),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _bius
              .mapIndexed(
                (index, e) => [
                  _buildBIUSItem(
                    index,
                    e.$1,
                    e.$2,
                  ),
                  if (index != 0 || index != _bius.length - 1) const _Divider(),
                ],
              )
              .flattened
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBIUSItem(
    int index,
    FlowySvgData icon,
    String richTextKey,
  ) {
    return _Item(
      size: const Size(62, 54),
      enableTopLeftRadius: index == 0,
      enableBottomLeftRadius: index == 0,
      enableTopRightRadius: index == _bius.length - 1,
      enableBottomRightRadius: index == _bius.length - 1,
      onTap: () {},
      icon: icon,
      isSelected: _isTextDecorationSelected(editorState, richTextKey),
      iconPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
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
    (FlowySvgs.toggle_list_s, ToggleListBlockKeys.type),
    (FlowySvgs.numbers_s, NumberedListBlockKeys.type),
    (FlowySvgs.m_bulleted_list_m, BulletedListBlockKeys.type),
    (FlowySvgs.quote_s, QuoteBlockKeys.type),
    (FlowySvgs.m_code_m, CodeBlockKeys.type),
    (FlowySvgs.math_lg, MathEquationBlockKeys.type),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _blockItems
              .mapIndexed(
                (index, e) => [
                  _buildBlockItem(
                    index,
                    e.$1,
                    e.$2,
                  ),
                  if (index != 0 || index != _blockItems.length - 1)
                    const _Divider(),
                ],
              )
              .flattened
              .toList(),
        ),
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
      onTap: () {},
      icon: icon,
      isSelected: _isBlockTypeSelected(editorState, blockType),
      iconPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.size,
    required this.onTap,
    required this.icon,
    required this.isSelected,
    required this.iconPadding,
    this.enableBottomLeftRadius = true,
    this.enableBottomRightRadius = true,
    this.enableTopLeftRadius = true,
    this.enableTopRightRadius = true,
  });

  final Size size;
  final VoidCallback onTap;
  final FlowySvgData icon;
  final bool isSelected;
  final EdgeInsets iconPadding;
  final bool enableTopLeftRadius;
  final bool enableTopRightRadius;
  final bool enableBottomRightRadius;
  final bool enableBottomLeftRadius;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(12);
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCF0) : null,
          borderRadius: BorderRadius.only(
            topLeft: enableTopLeftRadius ? radius : Radius.zero,
            topRight: enableTopRightRadius ? radius : Radius.zero,
            bottomRight: enableBottomRightRadius ? radius : Radius.zero,
            bottomLeft: enableBottomLeftRadius ? radius : Radius.zero,
          ),
        ),
        padding: iconPadding,
        child: FlowySvg(
          icon,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const HSpace(
      1.0,
      color: Colors.white,
    );
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
