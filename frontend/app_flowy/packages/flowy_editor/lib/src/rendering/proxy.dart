import 'package:flutter/rendering.dart';

import '../rendering/box.dart';

/* -------------------------------- Baseline -------------------------------- */

class RenderBaselineProxy extends RenderProxyBox {
  RenderBaselineProxy(
    RenderParagraph? child,
    TextStyle textStyle,
    EdgeInsets? padding,
  )   : _prototypePainter = TextPainter(
          text: TextSpan(text: ' ', style: textStyle),
          textDirection: TextDirection.ltr,
          strutStyle: StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true),
        ),
        super(child);

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    if (_prototypePainter.text!.style == value) {
      return;
    }
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  EdgeInsets? _padding;

  set padding(EdgeInsets value) {
    if (_padding == value) {
      return;
    }
    _padding = value;
    markNeedsLayout();
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _prototypePainter.computeDistanceToActualBaseline(baseline);

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout();
  }
}

/* ---------------------------------- Embed --------------------------------- */

class RenderEmbedProxy extends RenderProxyBox implements RenderContentProxyBox {
  RenderEmbedProxy(RenderBox? child) : super(child);

  @override
  List<TextBox> getBoxesForSelection(TextSelection textSelection) {
    if (!textSelection.isCollapsed) {
      return <TextBox>[TextBox.fromLTRBD(0, 0, size.width, size.height, TextDirection.ltr)];
    }

    final left = textSelection.extentOffset == 0 ? 0.0 : size.width;
    final right = textSelection.extentOffset == 0 ? 0.0 : size.width;
    return <TextBox>[TextBox.fromLTRBD(left, 0, right, size.height, TextDirection.ltr)];
  }

  @override
  double? getFullHeightForCaret(TextPosition position) => size.height;

  @override
  Offset getOffsetForCaret(TextPosition position, Rect? caretPrototype) {
    assert(position.offset <= 1 && position.offset >= 0);
    return position.offset == 0 ? Offset.zero : Offset(size.width, 0);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    return TextPosition(offset: offset.dx > size.width / 2 ? 1 : 0);
  }

  @override
  TextRange getWordBoundary(TextPosition position) => const TextRange(start: 0, end: 1);

  @override
  double getPreferredLineHeight() => size.height;
}

/* ---------------------------- Paragraph / Text ---------------------------- */

class RenderParagraphProxy extends RenderProxyBox implements RenderContentProxyBox {
  RenderParagraphProxy(
    RenderParagraph? child,
    TextStyle textStyle,
    TextAlign textAlign,
    TextDirection textDirection,
    double textScaleFactor,
    StrutStyle strutStyle,
    Locale locale,
    TextWidthBasis textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
  )   : _prototypePainter = TextPainter(
          text: TextSpan(text: ' ', style: textStyle),
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          strutStyle: strutStyle,
          locale: locale,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
        ),
        super(child);

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    if (_prototypePainter.text!.style == value) {
      return;
    }
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  set textAlign(TextAlign value) {
    if (_prototypePainter.textAlign == value) {
      return;
    }
    _prototypePainter.textAlign = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_prototypePainter.textDirection == value) {
      return;
    }
    _prototypePainter.textDirection = value;
    markNeedsLayout();
  }

  set textScaleFactor(double value) {
    if (_prototypePainter.textScaleFactor == value) {
      return;
    }
    _prototypePainter.textScaleFactor = value;
    markNeedsLayout();
  }

  set strutStyle(StrutStyle value) {
    if (_prototypePainter.strutStyle == value) {
      return;
    }
    _prototypePainter.strutStyle = value;
    markNeedsLayout();
  }

  set locale(Locale value) {
    if (_prototypePainter.locale == value) {
      return;
    }
    _prototypePainter.locale = value;
    markNeedsLayout();
  }

  set textWidthBasis(TextWidthBasis value) {
    if (_prototypePainter.textWidthBasis == value) {
      return;
    }
    _prototypePainter.textWidthBasis = value;
    markNeedsLayout();
  }

  set textHeightBehavior(TextHeightBehavior? value) {
    if (_prototypePainter.textHeightBehavior == value) {
      return;
    }
    _prototypePainter.textHeightBehavior = value;
    markNeedsLayout();
  }

  @override
  RenderParagraph? get child => super.child as RenderParagraph?;

  @override
  double getPreferredLineHeight() {
    return _prototypePainter.preferredLineHeight;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect? caretPrototype) =>
      child!.getOffsetForCaret(position, caretPrototype!);

  @override
  TextPosition getPositionForOffset(Offset offset) => child!.getPositionForOffset(offset);

  @override
  double? getFullHeightForCaret(TextPosition position) => child!.getFullHeightForCaret(position);

  @override
  TextRange getWordBoundary(TextPosition position) => child!.getWordBoundary(position);

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) => child!.getBoxesForSelection(selection);

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }
}
