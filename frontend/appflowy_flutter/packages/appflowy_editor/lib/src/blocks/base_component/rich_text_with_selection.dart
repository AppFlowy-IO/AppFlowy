import 'package:flutter/material.dart';

class RichTextWithSelection extends StatefulWidget {
  const RichTextWithSelection({
    super.key,
    required this.text,
    this.textSelection,
    this.selectionColor = const Color.fromARGB(100, 33, 149, 243),
    this.cursorColor = Colors.black,
    this.cursorWidth = 1.0,
    this.cursorHeight,
  });

  final TextSpan text;

  final TextSelection? textSelection;

  /// Selection
  final Color selectionColor;

  /// Cursor color
  final Color cursorColor;

  /// The width of the cursor in logical pixels.
  final double cursorWidth;

  /// The height of the cursor in logical pixels.
  /// If null, the cursor will be the same height as the text.
  final double? cursorHeight;

  @override
  State<RichTextWithSelection> createState() => _RichTextWithSelectionState();
}

class _RichTextWithSelectionState extends State<RichTextWithSelection> {
  final _richTextKey = GlobalKey(debugLabel: 'Rich Text Key');

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      key: _richTextKey,
      widget.text,
    );
  }
}
