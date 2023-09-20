extension GoogleFontsParser on String {
  String parseFontFamilyName() {
    final camelCase = RegExp('(?<=[a-z])[A-Z]');
    return replaceAll('_regular', '')
        .replaceAllMapped(camelCase, (m) => ' ${m.group(0)}');
  }
}
