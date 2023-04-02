import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/text_block/text_block_with_input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TextBlockWithIcon extends StatefulWidget {
  const TextBlockWithIcon({
    super.key,
    required this.icon,
    required this.node,
    this.onDebugMode = true,
    this.onTap,
    this.onDoubleTap,
    this.shortcuts = const [],
  });

  final Node node;
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
  late Delta delta;

  @override
  EditorState get editorState =>
      Provider.of<EditorState>(context, listen: false);

  @override
  void initState() {
    super.initState();

    delta = Delta.fromJson(widget.node.attributes['texts']);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      // crossAxisAlignment: CrossAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.icon,
        TextBlock(
          delta: delta,
          path: widget.node.path,
          onDebugMode: widget.onDebugMode,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          shortcuts: widget.shortcuts,
          onInsert: onInsert,
          onDelete: onDelete,
          onReplace: onReplace,
          onNonTextUpdate: onNonTextUpdate,
        )
      ],
    );
  }
}
