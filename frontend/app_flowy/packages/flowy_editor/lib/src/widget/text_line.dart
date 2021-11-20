import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../model/document/node/leaf.dart' as leaf;
import '../model/document/attribute.dart';
import '../model/document/node/line.dart';
import '../model/document/node/node.dart';
import '../rendering/text_line.dart';
import '../widget/proxy.dart';
import '../service/style.dart';
import '../service/cursor.dart';
import '../util/color.dart';

/* --------------------------------- Widget --------------------------------- */

class TextLine extends StatelessWidget {
  const TextLine({
    required this.line,
    required this.embedBuilder,
    required this.styles,
    this.textDirection,
    Key? key,
  }) : super(key: key);

  final Line line;
  final TextDirection? textDirection;
  final EmbedBuilderFuncion embedBuilder;
  final DefaultStyles styles;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    if (line.hasEmbed) {
      final embed = line.children.single as leaf.Embed;
      return EmbedProxy(embedBuilder(context, embed));
    }

    final textSpan = _buildTextSpan(context);
    final strutStyle = StrutStyle.fromTextStyle(textSpan.style!);
    final textAlign = _getTextAlign();
    final child = RichText(
      text: textSpan,
      textAlign: textAlign,
      textDirection: textDirection,
      strutStyle: strutStyle,
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
    );
    return RichTextProxy(
      child,
      textSpan.style!,
      textAlign,
      textDirection!,
      1,
      Localizations.localeOf(context),
      strutStyle,
      TextWidthBasis.parent,
      null,
    );
  }

  // TextStyle Decode

  TextAlign _getTextAlign() {
    final alignment = line.style.attributes[Attribute.align.key];
    if (Attribute.leftAlignment == alignment) {
      return TextAlign.left;
    } else if (Attribute.centerAlignment == alignment) {
      return TextAlign.center;
    } else if (Attribute.rightAlignment == alignment) {
      return TextAlign.right;
    } else if (Attribute.justifyAlignment == alignment) {
      return TextAlign.justify;
    }
    return TextAlign.start;
  }

  // Span Util

  TextSpan _buildTextSpan(BuildContext context) {
    final defaultStyles = styles;
    final children = line.children
        .map((child) => _getTextSpanFromNode(defaultStyles, child))
        .toList(growable: false);

    var textStyle = const TextStyle();

    // Placeholder
    if (line.style.containsKey(Attribute.placeholder.key)) {
      textStyle = defaultStyles.placeHolder!.style;
      return TextSpan(children: children, style: textStyle);
    }

    // Header
    final header = line.style.attributes[Attribute.header.key];
    final headerStyles = <Attribute, TextStyle>{
      Attribute.h1: defaultStyles.h1!.style,
      Attribute.h2: defaultStyles.h2!.style,
      Attribute.h3: defaultStyles.h3!.style,
    };
    textStyle =
        textStyle.merge(headerStyles[header] ?? defaultStyles.paragraph!.style);

    // Block
    final block = line.style.getBlockExceptHeader();
    TextStyle? blockStyle;
    if (Attribute.quoteBlock == block) {
      blockStyle = defaultStyles.quote!.style;
    } else if (Attribute.codeBlock == block) {
      blockStyle = defaultStyles.code!.style;
    } else if (block != null) {
      blockStyle = defaultStyles.lists!.style;
    }
    textStyle = textStyle.merge(blockStyle);

    return TextSpan(children: children, style: textStyle);
  }

  TextSpan _getTextSpanFromNode(DefaultStyles defaultStyles, Node node) {
    final textNode = node as leaf.Text;
    final style = textNode.style;

    // Inline Style
    final inlineStyles = <String, TextStyle?>{
      Attribute.bold.key: defaultStyles.bold,
      Attribute.italic.key: defaultStyles.italic,
      Attribute.link.key: defaultStyles.link,
      Attribute.underline.key: defaultStyles.underline,
      Attribute.strikeThrough.key: defaultStyles.strikeThrough,
    };
    var result = const TextStyle();
    inlineStyles.forEach((_key, _style) {
      if (style.values.any((val) => val.key == _key)) {
        result = _merge(result, _style!);
      }
    });

    // Font
    final font = textNode.style.attributes[Attribute.font.key];
    if (font != null && font.value != null) {
      result = result.merge(TextStyle(fontFamily: font.value));
    }

    // Size
    final size = textNode.style.attributes[Attribute.size.key];
    if (size != null && size.value != null) {
      switch (size.value) {
        case 'small':
          result = result.merge(defaultStyles.sizeSmall);
          break;
        case 'large':
          result = result.merge(defaultStyles.sizeLarge);
          break;
        case 'huge':
          result = result.merge(defaultStyles.sizeHuge);
          break;
        default:
          final fontSize = double.tryParse(size.value);
          if (fontSize != null) {
            result = result.merge(TextStyle(fontSize: fontSize));
          } else {
            throw 'Invalid size ${size.value}';
          }
      }
    }

    // Color
    final color = textNode.style.attributes[Attribute.color.key];
    if (color != null && color.value != null) {
      var textColor = defaultStyles.color;
      if (color.value is String) {
        textColor = stringToColor(color.value);
      }
      if (textColor != null) {
        result = result.merge(TextStyle(color: textColor));
      }
    }

    // Background
    final background = textNode.style.attributes[Attribute.background.key];
    if (background != null && background.value != null) {
      final backgroundColor = stringToColor(background.value);
      result = result.merge(TextStyle(backgroundColor: backgroundColor));
    }

    return TextSpan(text: textNode.value, style: result);
  }

  TextStyle _merge(TextStyle style, TextStyle otherStyle) {
    final decorations = <TextDecoration?>[];
    if (style.decoration != null) {
      decorations.add(style.decoration);
    }
    if (otherStyle.decoration != null) {
      decorations.add(otherStyle.decoration);
    }
    return style.merge(otherStyle).apply(
          decoration: TextDecoration.combine(
            List.castFrom<dynamic, TextDecoration>(decorations),
          ),
        );
  }
}

/* -------------------------- Render Object Widget -------------------------- */

class EditableTextLine extends RenderObjectWidget {
  const EditableTextLine(
    this.line,
    this.leading,
    this.body,
    this.indentWidth,
    this.verticalSpacing,
    this.textDirection,
    this.textSelection,
    this.color,
    this.enableInteractiveSelection,
    this.hasFocus,
    this.devicePixelRatio,
    this.cursorController,
  );

  final Line line;
  final Widget? leading;
  final Widget body;
  final double indentWidth;
  final Tuple2 verticalSpacing;
  final TextDirection textDirection;
  final TextSelection textSelection;
  final Color color;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final double devicePixelRatio;
  final CursorController cursorController;

  @override
  RenderObjectElement createElement() => TextLineElement(this);

  @override
  RenderEditableTextLine createRenderObject(BuildContext context) {
    return RenderEditableTextLine(
      line,
      textDirection,
      textSelection,
      enableInteractiveSelection,
      hasFocus,
      devicePixelRatio,
      _computePadding(),
      color,
      cursorController,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextLine renderObject) {
    renderObject
      ..line = line
      ..padding = _computePadding()
      ..textDirection = textDirection
      ..textSelection = textSelection
      ..color = color
      ..enableInteractiveSelection = enableInteractiveSelection
      ..hasFocus = hasFocus
      ..devicePixelRatio = devicePixelRatio
      ..cursorController = cursorController;
  }

  EdgeInsetsGeometry _computePadding() {
    return EdgeInsetsDirectional.only(
      start: indentWidth,
      top: verticalSpacing.item1,
      bottom: verticalSpacing.item2,
    );
  }
}
