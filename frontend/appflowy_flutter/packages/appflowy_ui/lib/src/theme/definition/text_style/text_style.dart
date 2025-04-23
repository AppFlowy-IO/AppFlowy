import 'package:appflowy_ui/src/theme/definition/text_style/base/default_text_style.dart';

class AppFlowyBaseTextStyle {
  factory AppFlowyBaseTextStyle.customFontFamily(String fontFamily) =>
      AppFlowyBaseTextStyle(
        heading1: TextThemeHeading1(fontFamily: fontFamily),
        heading2: TextThemeHeading2(fontFamily: fontFamily),
        heading3: TextThemeHeading3(fontFamily: fontFamily),
        heading4: TextThemeHeading4(fontFamily: fontFamily),
        headline: TextThemeHeadline(fontFamily: fontFamily),
        title: TextThemeTitle(fontFamily: fontFamily),
        body: TextThemeBody(fontFamily: fontFamily),
        caption: TextThemeCaption(fontFamily: fontFamily),
      );

  const AppFlowyBaseTextStyle({
    this.heading1 = const TextThemeHeading1(fontFamily: ''),
    this.heading2 = const TextThemeHeading2(fontFamily: ''),
    this.heading3 = const TextThemeHeading3(fontFamily: ''),
    this.heading4 = const TextThemeHeading4(fontFamily: ''),
    this.headline = const TextThemeHeadline(fontFamily: ''),
    this.title = const TextThemeTitle(fontFamily: ''),
    this.body = const TextThemeBody(fontFamily: ''),
    this.caption = const TextThemeCaption(fontFamily: ''),
  });

  final TextThemeType heading1;
  final TextThemeType heading2;
  final TextThemeType heading3;
  final TextThemeType heading4;
  final TextThemeType headline;
  final TextThemeType title;
  final TextThemeType body;
  final TextThemeType caption;
}
