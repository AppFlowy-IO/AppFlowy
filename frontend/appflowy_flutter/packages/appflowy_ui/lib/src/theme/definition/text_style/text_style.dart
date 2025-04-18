import 'package:appflowy_ui/src/theme/definition/text_style/base/default_text_style.dart';

class AppFlowyBaseTextStyle {
  const AppFlowyBaseTextStyle({
    this.heading1 = const TextThemeHeading1(),
    this.heading2 = const TextThemeHeading2(),
    this.heading3 = const TextThemeHeading3(),
    this.heading4 = const TextThemeHeading4(),
    this.headline = const TextThemeHeadline(),
    this.title = const TextThemeTitle(),
    this.body = const TextThemeBody(),
    this.caption = const TextThemeCaption(),
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
