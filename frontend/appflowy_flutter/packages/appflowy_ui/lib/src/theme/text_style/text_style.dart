import 'package:appflowy_ui/src/theme/text_style/base/default_text_style.dart';

class AppFlowyBaseTextStyle {
  const AppFlowyBaseTextStyle({
    this.heading = const TextThemeHeading(),
    this.headline = const TextThemeHeadline(),
    this.title = const TextThemeTitle(),
    this.body = const TextThemeBody(),
    this.caption = const TextThemeCaption(),
  });

  final TextThemeHeading heading;
  final TextThemeType headline;
  final TextThemeType title;
  final TextThemeType body;
  final TextThemeType caption;
}
