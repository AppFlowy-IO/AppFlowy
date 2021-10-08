import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'box.dart';

class BaselineProxy extends SingleChildRenderObjectWidget {
  const BaselineProxy({Key? key, Widget? child, this.textStyle, this.padding})
      : super(key: key, child: child);

  final TextStyle? textStyle;
  final EdgeInsets? padding;

  @override
  RenderBaselineProxy createRenderObject(BuildContext context) {
    return RenderBaselineProxy(
      null,
      textStyle!,
      padding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderBaselineProxy renderObject) {
    renderObject
      ..textStyle = textStyle!
      ..padding = padding!;
  }
}

class RenderBaselineProxy extends RenderProxyBox {
  RenderBaselineProxy(
    RenderParagraph? child,
    TextStyle textStyle,
    EdgeInsets? padding,
  )   : _prototypePainter = TextPainter(
            text: TextSpan(text: ' ', style: textStyle),
            textDirection: TextDirection.ltr,
            strutStyle:
                StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true)),
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
  double computeDistanceToActualBaseline(TextBaseline baseline) =>
      _prototypePainter.computeDistanceToActualBaseline(baseline);
  // SEE What happens + _padding?.top;

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout();
  }
}

class EmbedProxy extends SingleChildRenderObjectWidget {
  const EmbedProxy(Widget child) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) =>
      RenderEmbedProxy(null);
}

class RenderEmbedProxy extends RenderProxyBox implements RenderContentProxyBox {
  RenderEmbedProxy(RenderBox? child) : super(child);

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    if (!selection.isCollapsed) {
      return <TextBox>[
        TextBox.fromLTRBD(0, 0, size.width, size.height, TextDirection.ltr)
      ];
    }

    final left = selection.extentOffset == 0 ? 0.0 : size.width;
    final right = selection.extentOffset == 0 ? 0.0 : size.width;
    return <TextBox>[
      TextBox.fromLTRBD(left, 0, right, size.height, TextDirection.ltr)
    ];
  }

  @override
  double getFullHeightForCaret(TextPosition position) => size.height;

  @override
  Offset getOffsetForCaret(TextPosition position, Rect? caretPrototype) {
    assert(
        position.offset == 1 || position.offset == 0 || position.offset == -1);
    return position.offset <= 0
        ? Offset.zero
        : Offset(
            size.width - (caretPrototype == null ? 0 : caretPrototype.width),
            0);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) =>
      TextPosition(offset: offset.dx > size.width / 2 ? 1 : 0);

  @override
  TextRange getWordBoundary(TextPosition position) =>
      const TextRange(start: 0, end: 1);

  @override
  double getPreferredLineHeight() {
    return size.height;
  }
}

class RichTextProxy extends SingleChildRenderObjectWidget {
  const RichTextProxy(
    RichText child,
    this.textStyle,
    this.textAlign,
    this.textDirection,
    this.textScaleFactor,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
  ) : super(child: child);

  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double textScaleFactor;
  final Locale locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
        null,
        textStyle,
        textAlign,
        textDirection,
        textScaleFactor,
        strutStyle,
        locale,
        textWidthBasis,
        textHeightBehavior);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderParagraphProxy renderObject) {
    renderObject
      ..textStyle = textStyle
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..textScaleFactor = textScaleFactor
      ..locale = locale
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..textHeightBehavior = textHeightBehavior;
  }
}

class RenderParagraphProxy extends RenderProxyBox
    implements RenderContentProxyBox {
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
            textHeightBehavior: textHeightBehavior),
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
  TextPosition getPositionForOffset(Offset offset) =>
      child!.getPositionForOffset(offset);

  @override
  double? getFullHeightForCaret(TextPosition position) =>
      child!.getFullHeightForCaret(position);

  @override
  TextRange getWordBoundary(TextPosition position) =>
      child!.getWordBoundary(position);

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) =>
      child!.getBoxesForSelection(selection);

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout(
        minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }
}
