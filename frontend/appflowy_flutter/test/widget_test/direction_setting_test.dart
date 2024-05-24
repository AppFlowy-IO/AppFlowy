import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_radio_select.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_setting.pb.dart';
import 'package:appflowy/user/application/user_settings_service.dart';

import '../util.dart';

class MockAppearanceSettingsBloc
    extends MockBloc<AppearanceSettingsCubit, AppearanceSettingsState>
    implements AppearanceSettingsCubit {}

class MockDocumentAppearanceCubit extends Mock
    implements DocumentAppearanceCubit {}

class MockDocumentAppearance extends Mock implements DocumentAppearance {}

void main() {
  // ignore: unused_local_variable
  late AppFlowyUnitTest context;
  late AppearanceSettingsPB appearanceSettings;
  late DateTimeSettingsPB dateTimeSettings;

  setUp(() async {
    context = await AppFlowyUnitTest.ensureInitialized();
    appearanceSettings =
        await UserSettingsBackendService().getAppearanceSetting();
    dateTimeSettings = await UserSettingsBackendService().getDateTimeSettings();
  });

  testWidgets('TextDirectionSelect update default text direction setting',
      (WidgetTester tester) async {
    final appearanceSettingsState = AppearanceSettingsState.initial(
      AppTheme.fallback,
      appearanceSettings.themeMode,
      appearanceSettings.font,
      appearanceSettings.monospaceFont,
      appearanceSettings.layoutDirection,
      appearanceSettings.textDirection,
      appearanceSettings.enableRtlToolbarItems,
      appearanceSettings.locale,
      appearanceSettings.isMenuCollapsed,
      appearanceSettings.menuOffset,
      dateTimeSettings.dateFormat,
      dateTimeSettings.timeFormat,
      dateTimeSettings.timezoneId,
      appearanceSettings.documentSetting.cursorColor.isEmpty
          ? null
          : Color(
              int.parse(appearanceSettings.documentSetting.cursorColor),
            ),
      appearanceSettings.documentSetting.selectionColor.isEmpty
          ? null
          : Color(
              int.parse(
                appearanceSettings.documentSetting.selectionColor,
              ),
            ),
      1.0,
    );
    final mockAppearanceSettingsBloc = MockAppearanceSettingsBloc();
    when(() => mockAppearanceSettingsBloc.state).thenReturn(
      appearanceSettingsState,
    );

    final mockDocumentAppearanceCubit = MockDocumentAppearanceCubit();
    when(() => mockDocumentAppearanceCubit.stream).thenAnswer(
      (_) => Stream.fromIterable([MockDocumentAppearance()]),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppearanceSettingsCubit>.value(
            value: mockAppearanceSettingsBloc,
          ),
          BlocProvider<DocumentAppearanceCubit>.value(
            value: mockDocumentAppearanceCubit,
          ),
        ],
        child: MaterialApp(
          theme: appearanceSettingsState.lightTheme,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AppearanceSettingsCubit>.value(
                value: mockAppearanceSettingsBloc,
              ),
              BlocProvider<DocumentAppearanceCubit>.value(
                value: mockDocumentAppearanceCubit,
              ),
            ],
            child: const Scaffold(
              body: TextDirectionSelect(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        LocaleKeys.settings_workspacePage_textDirection_leftToRight.tr(),
      ),
      findsOne,
    );
    expect(
      find.text(
        LocaleKeys.settings_workspacePage_textDirection_rightToLeft.tr(),
      ),
      findsOne,
    );
    expect(
      find.text(
        LocaleKeys.settings_workspacePage_textDirection_auto.tr(),
      ),
      findsOne,
    );

    final radioSelectFinder =
        find.byType(SettingsRadioSelect<AppFlowyTextDirection>);
    expect(radioSelectFinder, findsOne);

    when(
      () => mockAppearanceSettingsBloc.setTextDirection(
        any<AppFlowyTextDirection?>(),
      ),
    ).thenAnswer((_) async => {});
    when(
      () => mockDocumentAppearanceCubit.syncDefaultTextDirection(
        any<String?>(),
      ),
    ).thenAnswer((_) async {});

    final radioSelect = tester.widget(radioSelectFinder)
        as SettingsRadioSelect<AppFlowyTextDirection>;
    final rtlSelect = radioSelect.items
        .firstWhere((select) => select.value == AppFlowyTextDirection.rtl);
    radioSelect.onChanged(rtlSelect);

    verify(
      () => mockAppearanceSettingsBloc.setTextDirection(
        any<AppFlowyTextDirection?>(),
      ),
    ).called(1);
    verify(
      () => mockDocumentAppearanceCubit.syncDefaultTextDirection(
        any<String?>(),
      ),
    ).called(1);
  });
}
