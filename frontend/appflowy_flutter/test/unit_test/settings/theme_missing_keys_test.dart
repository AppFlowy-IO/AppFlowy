import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flowy_infra/colorscheme/default_colorscheme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme missing keys', () {
    test('no missing keys', () {
      const colorScheme = DefaultColorScheme.light();
      final toJson = colorScheme.toJson();

      expect(toJson.containsKey('surface'), true);

      final missingKeys = FlowyColorScheme.getMissingKeys(toJson);
      expect(missingKeys.isEmpty, true);
    });

    test('missing surface and bg2', () {
      const colorScheme = DefaultColorScheme.light();
      final toJson = colorScheme.toJson()
        ..remove('surface')
        ..remove('bg2');

      expect(toJson.containsKey('surface'), false);
      expect(toJson.containsKey('bg2'), false);

      final missingKeys = FlowyColorScheme.getMissingKeys(toJson);
      expect(missingKeys.length, 2);
      expect(missingKeys.contains('surface'), true);
      expect(missingKeys.contains('bg2'), true);
    });
  });
}
