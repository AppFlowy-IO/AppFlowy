///
/// Supported partial rendering types:
///   bold, italic,
///   underline, strikethrough,
///   color, font,
///   href
///
/// Supported global rendering types:
///   heading: h1, h2, h3, h4, h5, h6, ...
///   block quote,
///   list: ordered list, bulleted list,
///   code block
///
class BuiltInAttributeKey {
  static String bold = 'bold';
  static String italic = 'italic';
  static String underline = 'underline';
  static String strikethrough = 'strikethrough';
  static String color = 'color';
  static String backgroundColor = 'backgroundColor';
  static String font = 'font';
  static String href = 'href';

  static String subtype = 'subtype';
  static String heading = 'heading';
  static String h1 = 'h1';
  static String h2 = 'h2';
  static String h3 = 'h3';
  static String h4 = 'h4';
  static String h5 = 'h5';
  static String h6 = 'h6';

  static String bulletedList = 'bulleted-list';
  static String numberList = 'number-list';

  static String quote = 'quote';
  static String checkbox = 'checkbox';
  static String code = 'code';
  static String number = 'number';

  static List<String> partialStyleKeys = [
    BuiltInAttributeKey.bold,
    BuiltInAttributeKey.italic,
    BuiltInAttributeKey.underline,
    BuiltInAttributeKey.strikethrough,
    BuiltInAttributeKey.backgroundColor,
    BuiltInAttributeKey.color,
    BuiltInAttributeKey.href,
    BuiltInAttributeKey.code,
  ];

  static List<String> globalStyleKeys = [
    BuiltInAttributeKey.subtype,
    BuiltInAttributeKey.heading,
    BuiltInAttributeKey.checkbox,
    BuiltInAttributeKey.bulletedList,
    BuiltInAttributeKey.numberList,
    BuiltInAttributeKey.quote,
  ];
}
