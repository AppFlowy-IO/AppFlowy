import 'dart:ui';

import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import '../util.dart';

void main() {
  setUpAll(() async {
    AppFlowyUnitTest.ensureInitialized();
  });

  group('Select App Theme', () {
    test('Passing invalid theme name returns Default theme as fallback', () {
      final AppTheme t = AppTheme.fromName('whatever');
      expect(t.themeName, "Default");
    });

    test('Passing invalid color scheme throws exception', () {
      expect(
        () => {FlowyColorScheme.builtIn("light", Brightness.light)},
        throwsException,
      );
    });
  });
}
