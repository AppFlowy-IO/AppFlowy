import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/text_block/text_block_with_input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TextBlockWithIcon extends StatefulWidget {
  const TextBlockWithIcon({
    super.key,
    required this.icon,
    required this.textNode,
    this.onDebugMode = true,
    this.onTap,
    this.onDoubleTap,
    this.shortcuts = const [],
  });

  final TextNode textNode;
  final bool onDebugMode;
  final Future<void> Function(Map<String, dynamic> values)? onTap;
  final Future<void> Function(Map<String, dynamic> values)? onDoubleTap;
  final List<ShortcutEvent> shortcuts;

  final Widget icon;

  @override
  State<TextBlockWithIcon> createState() => _TextBlockWithIconState();
}

class _TextBlockWithIconState extends State<TextBlockWithIcon>
    with TextBlockWithInput {

  @override
  EditorState get editorState => Provider.of<EditorState>(context, listen: false);

  @override
  // TODO: implement textNode
  TextNode get textNode => throw UnimplementedError();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.icon,
        TextBlock(
          delta: widget.textNode.delta,
          path: widget.textNode.,
          onDebugMode: widget.onDebugMode,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          shortcuts: widget.shortcuts,
        )
      ],
    );
  }


}
