import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
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
    late DateTimeSettingsPB dateTimeSettings;

    setUp(() async {
      appearanceSetting =
          await UserSettingsBackendService().getAppearanceSetting();
      dateTimeSettings =
          await UserSettingsBackendService().getDateTimeSettings();
      await blocResponseFuture();
    });

    blocTest<AppearanceSettingsCubit, AppearanceSettingsState>(
      'default theme',
      build: () => AppearanceSettingsCubit(
        appearanceSetting,
        dateTimeSettings,
        AppTheme.fallback,
      ),
      verify: (bloc) {
        expect(bloc.state.font, defaultFontFamily);
        expect(bloc.state.monospaceFont, 'SF Mono');
        expect(bloc.state.themeMode, ThemeMode.system);
      },
    );

    blocTest<AppearanceSettingsCubit, AppearanceSettingsState>(
      'save key/value',
      build: () => AppearanceSettingsCubit(
        appearanceSetting,
        dateTimeSettings,
        AppTheme.fallback,
      ),
      act: (bloc) {
        bloc.setKeyValue("123", "456");
      },
      verify: (bloc) {
        expect(bloc.getValue("123"), "456");
      },
    );

    blocTest<AppearanceSettingsCubit, AppearanceSettingsState>(
      'remove key/value',
      build: () => AppearanceSettingsCubit(
        appearanceSetting,
        dateTimeSettings,
        AppTheme.fallback,
      ),
      act: (bloc) {
        bloc.setKeyValue("123", null);
      },
      verify: (bloc) {
        expect(bloc.getValue("123"), null);
      },
    );

    blocTest<AppearanceSettingsCubit, AppearanceSettingsState>(
      'initial state uses fallback theme',
      build: () => AppearanceSettingsCubit(
        appearanceSetting,
        dateTimeSettings,
        AppTheme.fallback,
      ),
      verify: (bloc) {
        expect(bloc.state.appTheme.themeName, AppTheme.fallback.themeName);
      },
    );
  });
}
