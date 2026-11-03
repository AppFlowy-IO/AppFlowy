import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../util.dart';

class MockAppearanceSettingsBloc
    extends MockBloc<AppearanceSettingsCubit, AppearanceSettingsState>
    implements AppearanceSettingsCubit {}

void main() {
  late AppearanceSettingsPB appearanceSettings;
  late DateTimeSettingsPB dateTimeSettings;

  setUp(() async {
    await AppFlowyUnitTest.ensureInitialized();
    appearanceSettings =
        await UserSettingsBackendService().getAppearanceSetting();
    dateTimeSettings = await UserSettingsBackendService().getDateTimeSettings();
  });

  AppearanceSettingsState buildState() => AppearanceSettingsState.initial(
        AppTheme.fallback,
        appearanceSettings.themeMode,
        appearanceSettings.font,
        appearanceSettings.layoutDirection,
        appearanceSettings.textDirection,
        appearanceSettings.enableRtlToolbarItems,
        appearanceSettings.locale,
        appearanceSettings.isMenuCollapsed,
        appearanceSettings.menuOffset,
        dateTimeSettings.dateFormat,
        dateTimeSettings.timeFormat,
        dateTimeSettings.timezoneId,
        null,
        null,
        1.0,
      );

  Future<MockAppearanceSettingsBloc> pumpSwitcher(
    WidgetTester tester, {
    required bool hideSubPagesInSidebar,
  }) async {
    final state = buildState().copyWith(
      hideSubPagesInSidebar: hideSubPagesInSidebar,
    );
    final bloc = MockAppearanceSettingsBloc();
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.setHideSubPagesInSidebar(any<bool>()))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      BlocProvider<AppearanceSettingsCubit>.value(
        value: bloc,
        child: MaterialApp(
          theme: state.lightTheme,
          home: const Scaffold(body: HideSubPagesInSidebarSwitcher()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return bloc;
  }

  testWidgets('HideSubPagesInSidebarSwitcher reflects the current setting',
      (tester) async {
    await pumpSwitcher(tester, hideSubPagesInSidebar: false);

    expect(
      find.text(LocaleKeys.settings_workspacePage_sidebar_hideSubPages.tr()),
      findsOneWidget,
    );
    expect(
      find.text(
        LocaleKeys.settings_workspacePage_sidebar_hideSubPagesHint.tr(),
      ),
      findsOneWidget,
    );

    final toggle = tester.widget<Toggle>(
      find.byKey(const Key('HideSubPagesInSidebarToggle')),
    );
    expect(toggle.value, false);
  });

  testWidgets('HideSubPagesInSidebarSwitcher turns the setting on when tapped',
      (tester) async {
    final bloc = await pumpSwitcher(tester, hideSubPagesInSidebar: false);

    await tester.tap(find.byKey(const Key('HideSubPagesInSidebarToggle')));
    await tester.pumpAndSettle();

    verify(() => bloc.setHideSubPagesInSidebar(true)).called(1);
  });

  testWidgets('HideSubPagesInSidebarSwitcher turns the setting off when tapped',
      (tester) async {
    final bloc = await pumpSwitcher(tester, hideSubPagesInSidebar: true);

    expect(
      tester
          .widget<Toggle>(
            find.byKey(const Key('HideSubPagesInSidebarToggle')),
          )
          .value,
      true,
    );

    await tester.tap(find.byKey(const Key('HideSubPagesInSidebarToggle')));
    await tester.pumpAndSettle();

    verify(() => bloc.setHideSubPagesInSidebar(false)).called(1);
  });
}
