import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/text_block/shortcuts/text_block_shortcuts.dart';
import 'package:flutter/material.dart';

class TextBlockWithIcon extends StatelessWidget {
  const TextBlockWithIcon({
    Key? key,
    required this.icon,
    required this.textBlockKey,
    required this.crossAxisAlignment,
    required this.path,
    required this.delta,
    this.textSpanDecorator,
  }) : super(key: key);

  final GlobalKey<State<StatefulWidget>> textBlockKey;
  final Widget icon;
  final Path path;
  final Delta delta;
  final CrossAxisAlignment crossAxisAlignment;
  final TextSpanDecorator? textSpanDecorator;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        icon,
        TextBlock(
          key: textBlockKey,
          path: path,
          delta: delta,
          shortcuts: textBlockShortcuts,
          textSpanDecorator: textSpanDecorator,
        ),
      ],
    );
  }
}
