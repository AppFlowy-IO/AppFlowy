import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/font_family_setting.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppearanceSettingsCubit extends Mock
    implements AppearanceSettingsCubit {}

class MockDocumentAppearanceCubit extends Mock
    implements DocumentAppearanceCubit {}

class MockAppearanceSettingsState extends Mock
    implements AppearanceSettingsState {}

class MockDocumentAppearance extends Mock implements DocumentAppearance {}

void main() {
  late MockAppearanceSettingsCubit appearanceSettingsCubit;
  late MockDocumentAppearanceCubit documentAppearanceCubit;

  setUp(() {
    appearanceSettingsCubit = MockAppearanceSettingsCubit();
    when(() => appearanceSettingsCubit.stream).thenAnswer(
      (_) => Stream.fromIterable([MockAppearanceSettingsState()]),
    );
    documentAppearanceCubit = MockDocumentAppearanceCubit();
    when(() => documentAppearanceCubit.stream).thenAnswer(
      (_) => Stream.fromIterable([MockDocumentAppearance()]),
    );
  });

  testWidgets('ThemeFontFamilySetting updates font family on selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppearanceSettingsCubit>.value(
            value: appearanceSettingsCubit,
          ),
          BlocProvider<DocumentAppearanceCubit>.value(
            value: documentAppearanceCubit,
          ),
        ],
        child: MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AppearanceSettingsCubit>.value(
                value: appearanceSettingsCubit,
              ),
              BlocProvider<DocumentAppearanceCubit>.value(
                value: documentAppearanceCubit,
              ),
            ],
            child: Scaffold(
              body: ThemeFontFamilySetting(
                currentFontFamily: builtInFontFamily(),
              ),
            ),
          ),
        ),
      ),
    );

    final popover = find.byType(AppFlowyPopover);
    await tester.tap(popover);
    await tester.pumpAndSettle();

    // Verify the initial font family
    expect(find.text(builtInFontFamily()), findsAtLeastNWidgets(1));
    when(() => appearanceSettingsCubit.setFontFamily(any<String>()))
        .thenAnswer((_) async {});
    verifyNever(() => appearanceSettingsCubit.setFontFamily(any<String>()));
    when(() => documentAppearanceCubit.syncFontFamily(any<String>()))
        .thenAnswer((_) async {});
    verifyNever(() => documentAppearanceCubit.syncFontFamily(any<String>()));

    // Tap on a different font family
    final abel = find.textContaining('Abel');
    await tester.tap(abel);
    await tester.pumpAndSettle();

    // Verify that the font family is updated
    verify(() => appearanceSettingsCubit.setFontFamily(any<String>()))
        .called(1);
    verify(() => documentAppearanceCubit.syncFontFamily(any<String>()))
        .called(1);
  });
}
