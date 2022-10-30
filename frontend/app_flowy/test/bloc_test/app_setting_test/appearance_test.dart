import 'package:app_flowy/user/application/user_settings_service.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  // ignore: unused_local_variable
  late AppFlowyUnitTest context;
  setUpAll(() async {
    context = await AppFlowyUnitTest.ensureInitialized();
  });

  group('$AppearanceSetting', () {
    late AppearanceSetting appearanceSetting;
    setUp(() async {
      final setting = await SettingsFFIService().getAppearanceSetting();
      appearanceSetting = AppearanceSetting(setting);
      await blocResponseFuture();
    });

    test('default theme', () {
      expect(appearanceSetting.theme.ty, ThemeType.light);
    });

    test('save key/value', () async {
      appearanceSetting.setKeyValue("123", "456");
    });

    test('read key/value', () {
      expect(appearanceSetting.getValue("123"), "456");
    });

    test('remove key/value', () {
      appearanceSetting.setKeyValue("123", null);
    });

    test('read key/value', () {
      expect(appearanceSetting.getValue("123"), null);
    });
  });
}
