import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DebuggableRichText extends StatefulWidget {
  final InlineSpan text;
  final GlobalKey textKey;

  const DebuggableRichText({
    Key? key,
    required this.text,
    required this.textKey,
  }) : super(key: key);

  @override
  State<DebuggableRichText> createState() => _DebuggableRichTextState();
}

class _DebuggableRichTextState extends State<DebuggableRichText> {
  final List<Rect> _textRects = [];

  RenderParagraph get _renderParagraph =>
      widget.textKey.currentContext?.findRenderObject() as RenderParagraph;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateTextRects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: _BoxPainter(
            rects: _textRects,
          ),
        ),
        RichText(
          key: widget.textKey,
          text: widget.text,
        ),
      ],
    );
  }

  void _updateTextRects() {
    setState(() {
      _textRects
        ..clear()
        ..addAll(
          _computeLocalSelectionRects(
            TextSelection(
              baseOffset: 0,
              extentOffset: widget.text.toPlainText().length,
            ),
          ),
        );
    });
  }

  List<Rect> _computeLocalSelectionRects(TextSelection selection) {
    final textBoxes = _renderParagraph.getBoxesForSelection(selection);
    return textBoxes.map((box) => box.toRect()).toList();
  }
}

class _BoxPainter extends CustomPainter {
  final List<Rect> _rects;
  final Paint _paint;

  _BoxPainter({
    required List<Rect> rects,
    bool fill = false,
  })  : _rects = rects,
        _paint = Paint() {
    _paint.style = fill ? PaintingStyle.fill : PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final rect in _rects) {
      canvas.drawRect(
        rect,
        _paint
          ..color = Color(
            (Random().nextDouble() * 0xFFFFFF).toInt(),
          ).withOpacity(1.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
