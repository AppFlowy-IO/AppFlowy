import 'package:app_flowy/user/application/user_settings_service.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_setting.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  // ignore: unused_local_variable
  late AppFlowyUnitTest context;
  setUpAll(() async {
    context = await AppFlowyUnitTest.ensureInitialized();
  });

  group('$AppearanceSettingsCubit', () {
    late AppearanceSettingsPB appearanceSetting;
    setUp(() async {
      appearanceSetting = await SettingsFFIService().getAppearanceSetting();
      await blocResponseFuture();
    });

    blocTest<AppearanceSettingsCubit, AppearanceSettingsState>(
      'default theme',
      build: () => AppearanceSettingsCubit(appearanceSetting),
      verify: (bloc) {
        expect(bloc.state.themeName, "light");
      },
    );

    blocTest<AppearanceSettingsCubit, AppearanceSettingsState>(
      'save key/value',
      build: () => AppearanceSettingsCubit(appearanceSetting),
      act: (bloc) {
        bloc.setKeyValue("123", "456");
      },
      verify: (bloc) {
        expect(bloc.getValue("123"), "456");
      },
    );

    blocTest<AppearanceSettingsCubit, AppearanceSettingsState>(
      'remove key/value',
      build: () => AppearanceSettingsCubit(appearanceSetting),
      act: (bloc) {
        bloc.setKeyValue("123", null);
      },
      verify: (bloc) {
        expect(bloc.getValue("123"), null);
      },
    );
  });
}
