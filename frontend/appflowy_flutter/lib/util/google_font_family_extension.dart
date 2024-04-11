import 'package:appflowy/shared/patterns/common_patterns.dart';

extension GoogleFontsParser on String {
  String parseFontFamilyName() => replaceAll('_regular', '')
      .replaceAllMapped(camelCaseRegex, (m) => ' ${m.group(0)}');
}
