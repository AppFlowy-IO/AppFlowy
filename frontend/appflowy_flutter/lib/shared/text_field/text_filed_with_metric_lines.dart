import 'package:flutter/material.dart';

class TextFieldWithMetricLines extends StatefulWidget {
  const TextFieldWithMetricLines({
    super.key,
    this.controller,
    this.focusNode,
    this.maxLines,
    this.style,
    this.decoration,
    this.onLineCountChange,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int? maxLines;
  final TextStyle? style;
  final InputDecoration? decoration;
  final void Function(int count)? onLineCountChange;

  @override
  State<TextFieldWithMetricLines> createState() =>
      _TextFieldWithMetricLinesState();
}

class _TextFieldWithMetricLinesState extends State<TextFieldWithMetricLines> {
  final key = GlobalKey();
  late final controller = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      updateDisplayedLineCount(context);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      // dispose the controller if it was created by this widget
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: key,
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      style: widget.style,
      decoration: widget.decoration,
      onChanged: (_) => updateDisplayedLineCount(context),
    );
  }

  // calculate the number of lines that would be displayed in the text field
  void updateDisplayedLineCount(BuildContext context) {
    if (widget.onLineCountChange == null) {
      return;
    }

    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) {
      return;
    }

    final size = renderObject.size;
    final text = controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: false,
    );
    final textPainter = TextPainter(
      text: text,
      textDirection: Directionality.of(context),
    );

    textPainter.layout(minWidth: size.width, maxWidth: size.width);

    final lines = textPainter.computeLineMetrics().length;
    widget.onLineCountChange?.call(lines);
  }
}
