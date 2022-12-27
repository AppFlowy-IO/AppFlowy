import 'package:app_flowy/workspace/presentation/settings/widgets/settings_appearance_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ThemeTypeSetting themeTypeSetting;
  setUpAll(() {
    themeTypeSetting = const ThemeTypeSetting(
      currentThemeType: 'light',
    );
  });

  test(
    "check theme labels",
    () {
      String defaultThemeDisplayName =
          themeTypeSetting.getThemeNameForDisplaying('light');
      expect(defaultThemeDisplayName,
          'settings.appearance.themeType.defaultTheme');
      defaultThemeDisplayName =
          themeTypeSetting.getThemeNameForDisplaying('dandelion');
      expect(defaultThemeDisplayName,
          'settings.appearance.themeType.dandelionCommunity');
    },
  );
}
