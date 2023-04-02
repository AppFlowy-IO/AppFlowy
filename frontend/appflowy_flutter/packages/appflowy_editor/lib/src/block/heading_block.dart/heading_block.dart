import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/base_component/selectable/text_selectable_state_mixin.dart';
import 'package:appflowy_editor/src/block/text_block/shortcuts/text_block_shortcuts.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

const _headingMap = {
  1: 32.0,
  2: 28.0,
  3: 24.0,
  4: 18.0,
  5: 18.0,
  6: 18.0,
};

class HeadingBlock extends StatefulWidget {
  const HeadingBlock({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<HeadingBlock> createState() => _HeadingBlockState();
}

class _HeadingBlockState extends State<HeadingBlock>
    with TextBlockSelectableStateMixin<HeadingBlock> {
  int get _heading => widget.node.attributes['heading'] as int? ?? 1;

  @override
  Widget build(BuildContext context) {
    final delta = Delta.fromJson(List.from(widget.node.attributes['texts']));
    return TextBlock(
      key: textBlockKey,
      delta: delta,
      path: widget.node.path,
      textSpanDecorator: _textSpanDecorator,
      shortcuts: textBlockShortcuts,
    );
  }

  TextSpan _textSpanDecorator(TextSpan textSpan) => textSpan.updateTextStyle(
        TextStyle(
          fontSize: _headingMap[_heading] ?? 18.0,
          fontWeight: FontWeight.bold,
        ),
      );
}
