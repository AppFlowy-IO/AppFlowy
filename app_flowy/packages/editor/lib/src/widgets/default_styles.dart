import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

class QuillStyles extends InheritedWidget {
  const QuillStyles({
    required this.data,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  final DefaultStyles data;

  @override
  bool updateShouldNotify(QuillStyles oldWidget) {
    return data != oldWidget.data;
  }

  static DefaultStyles? getStyles(BuildContext context, bool nullOk) {
    final widget = context.dependOnInheritedWidgetOfExactType<QuillStyles>();
    if (widget == null && nullOk) {
      return null;
    }
    assert(widget != null);
    return widget!.data;
  }
}

class DefaultTextBlockStyle {
  DefaultTextBlockStyle(
    this.style,
    this.verticalSpacing,
    this.lineSpacing,
    this.decoration,
  );

  final TextStyle style;

  final Tuple2<double, double> verticalSpacing;

  final Tuple2<double, double> lineSpacing;

  final BoxDecoration? decoration;
}

class DefaultStyles {
  DefaultStyles({
    this.h1,
    this.h2,
    this.h3,
    this.paragraph,
    this.bold,
    this.italic,
    this.small,
    this.underline,
    this.strikeThrough,
    this.inlineCode,
    this.link,
    this.color,
    this.placeHolder,
    this.lists,
    this.quote,
    this.code,
    this.indent,
    this.align,
    this.leading,
    this.sizeSmall,
    this.sizeLarge,
    this.sizeHuge,
  });

  final DefaultTextBlockStyle? h1;
  final DefaultTextBlockStyle? h2;
  final DefaultTextBlockStyle? h3;
  final DefaultTextBlockStyle? paragraph;
  final TextStyle? bold;
  final TextStyle? italic;
  final TextStyle? small;
  final TextStyle? underline;
  final TextStyle? strikeThrough;
  final TextStyle? inlineCode;
  final TextStyle? sizeSmall; // 'small'
  final TextStyle? sizeLarge; // 'large'
  final TextStyle? sizeHuge; // 'huge'
  final TextStyle? link;
  final Color? color;
  final DefaultTextBlockStyle? placeHolder;
  final DefaultTextBlockStyle? lists;
  final DefaultTextBlockStyle? quote;
  final DefaultTextBlockStyle? code;
  final DefaultTextBlockStyle? indent;
  final DefaultTextBlockStyle? align;
  final DefaultTextBlockStyle? leading;

  static DefaultStyles getInstance(BuildContext context) {
    final themeData = Theme.of(context);
    final defaultTextStyle = DefaultTextStyle.of(context);
    final baseStyle = defaultTextStyle.style.copyWith(
      fontSize: 16,
      height: 1.3,
    );
    const baseSpacing = Tuple2<double, double>(6, 0);
    String fontFamily;
    switch (themeData.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        fontFamily = 'Menlo';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        fontFamily = 'Roboto Mono';
        break;
      default:
        throw UnimplementedError();
    }

    return DefaultStyles(
        h1: DefaultTextBlockStyle(
            defaultTextStyle.style.copyWith(
              fontSize: 34,
              color: defaultTextStyle.style.color!.withOpacity(0.70),
              height: 1.15,
              fontWeight: FontWeight.w300,
            ),
            const Tuple2(16, 0),
            const Tuple2(0, 0),
            null),
        h2: DefaultTextBlockStyle(
            defaultTextStyle.style.copyWith(
              fontSize: 24,
              color: defaultTextStyle.style.color!.withOpacity(0.70),
              height: 1.15,
              fontWeight: FontWeight.normal,
            ),
            const Tuple2(8, 0),
            const Tuple2(0, 0),
            null),
        h3: DefaultTextBlockStyle(
            defaultTextStyle.style.copyWith(
              fontSize: 20,
              color: defaultTextStyle.style.color!.withOpacity(0.70),
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
            const Tuple2(8, 0),
            const Tuple2(0, 0),
            null),
        paragraph: DefaultTextBlockStyle(
            baseStyle, const Tuple2(0, 0), const Tuple2(0, 0), null),
        bold: const TextStyle(fontWeight: FontWeight.bold),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        small: const TextStyle(fontSize: 12, color: Colors.black45),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
        inlineCode: TextStyle(
          color: Colors.blue.shade900.withOpacity(0.9),
          fontFamily: fontFamily,
          fontSize: 13,
        ),
        link: TextStyle(
          color: themeData.colorScheme.secondary,
          decoration: TextDecoration.underline,
        ),
        placeHolder: DefaultTextBlockStyle(
            defaultTextStyle.style.copyWith(
              fontSize: 20,
              height: 1.5,
              color: Colors.grey.withOpacity(0.6),
            ),
            const Tuple2(0, 0),
            const Tuple2(0, 0),
            null),
        lists: DefaultTextBlockStyle(
            baseStyle, baseSpacing, const Tuple2(0, 6), null),
        quote: DefaultTextBlockStyle(
            TextStyle(color: baseStyle.color!.withOpacity(0.6)),
            baseSpacing,
            const Tuple2(6, 2),
            BoxDecoration(
              border: Border(
                left: BorderSide(width: 4, color: Colors.grey.shade300),
              ),
            )),
        code: DefaultTextBlockStyle(
            TextStyle(
              color: Colors.blue.shade900.withOpacity(0.9),
              fontFamily: fontFamily,
              fontSize: 13,
              height: 1.15,
            ),
            baseSpacing,
            const Tuple2(0, 0),
            BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(2),
            )),
        indent: DefaultTextBlockStyle(
            baseStyle, baseSpacing, const Tuple2(0, 6), null),
        align: DefaultTextBlockStyle(
            baseStyle, const Tuple2(0, 0), const Tuple2(0, 0), null),
        leading: DefaultTextBlockStyle(
            baseStyle, const Tuple2(0, 0), const Tuple2(0, 0), null),
        sizeSmall: const TextStyle(fontSize: 10),
        sizeLarge: const TextStyle(fontSize: 18),
        sizeHuge: const TextStyle(fontSize: 22));
  }

  DefaultStyles merge(DefaultStyles other) {
    return DefaultStyles(
        h1: other.h1 ?? h1,
        h2: other.h2 ?? h2,
        h3: other.h3 ?? h3,
        paragraph: other.paragraph ?? paragraph,
        bold: other.bold ?? bold,
        italic: other.italic ?? italic,
        small: other.small ?? small,
        underline: other.underline ?? underline,
        strikeThrough: other.strikeThrough ?? strikeThrough,
        inlineCode: other.inlineCode ?? inlineCode,
        link: other.link ?? link,
        color: other.color ?? color,
        placeHolder: other.placeHolder ?? placeHolder,
        lists: other.lists ?? lists,
        quote: other.quote ?? quote,
        code: other.code ?? code,
        indent: other.indent ?? indent,
        align: other.align ?? align,
        leading: other.leading ?? leading,
        sizeSmall: other.sizeSmall ?? sizeSmall,
        sizeLarge: other.sizeLarge ?? sizeLarge,
        sizeHuge: other.sizeHuge ?? sizeHuge);
  }
}
