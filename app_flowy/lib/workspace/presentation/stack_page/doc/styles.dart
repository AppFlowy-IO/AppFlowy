import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:tuple/tuple.dart';
import 'package:flowy_infra/theme.dart';

DefaultStyles customStyles(BuildContext context) {
  const baseSpacing = Tuple2<double, double>(6, 0);
  final defaultTextStyle = DefaultTextStyle.of(context);
  final baseStyle = defaultTextStyle.style.copyWith(
    fontSize: 16,
    height: 1.3,
  );
  final theme = context.watch<AppTheme>();
  final themeData = theme.themeData;
  final fontFamily = makeFontFamily(themeData);

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
      paragraph: DefaultTextBlockStyle(baseStyle, const Tuple2(10, 0), const Tuple2(0, 0), null),
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
      lists: DefaultTextBlockStyle(baseStyle, baseSpacing, const Tuple2(0, 6), null),
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
      indent: DefaultTextBlockStyle(baseStyle, baseSpacing, const Tuple2(0, 6), null),
      align: DefaultTextBlockStyle(baseStyle, const Tuple2(0, 0), const Tuple2(0, 0), null),
      leading: DefaultTextBlockStyle(baseStyle, const Tuple2(0, 0), const Tuple2(0, 0), null),
      sizeSmall: const TextStyle(fontSize: 10),
      sizeLarge: const TextStyle(fontSize: 18),
      sizeHuge: const TextStyle(fontSize: 22));
}

String makeFontFamily(ThemeData themeData) {
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
  return fontFamily;
}
