import 'package:flutter/widgets.dart';

import '../model/document/node/leaf.dart';
import '../rendering/proxy.dart';

/* -------------------------------- Baseline -------------------------------- */

class BaselineProxy extends SingleChildRenderObjectWidget {
  const BaselineProxy({
    Key? key,
    Widget? child,
    this.textStyle,
    this.padding,
  }) : super(key: key, child: child);

  final TextStyle? textStyle;
  final EdgeInsets? padding;

  @override
  RenderBaselineProxy createRenderObject(BuildContext context) {
    return RenderBaselineProxy(null, textStyle!, padding);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderBaselineProxy renderObject) {
    renderObject
      ..textStyle = textStyle!
      ..padding = padding!;
  }
}

/* ---------------------------------- Embed --------------------------------- */

typedef EmbedBuilderFuncion = Widget Function(BuildContext context, Embed node);

class EmbedProxy extends SingleChildRenderObjectWidget {
  const EmbedProxy(Widget child) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) => RenderEmbedProxy(null);
}

/* ---------------------------------- Text ---------------------------------- */

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
      textHeightBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderParagraphProxy renderObject) {
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
