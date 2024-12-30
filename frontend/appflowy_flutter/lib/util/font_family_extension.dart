import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:easy_localization/easy_localization.dart';

extension FontFamilyExtension on String {
  String parseFontFamilyName() => replaceAll('_regular', '')
      .replaceAllMapped(camelCaseRegex, (m) => ' ${m.group(0)}');

  // display the default font name if the font family name is empty
  //  or using the default font family
  String get fontFamilyDisplayName => isEmpty || this == defaultFontFamily
      ? LocaleKeys.settings_appearance_fontFamily_defaultFont.tr()
      : parseFontFamilyName();
}
