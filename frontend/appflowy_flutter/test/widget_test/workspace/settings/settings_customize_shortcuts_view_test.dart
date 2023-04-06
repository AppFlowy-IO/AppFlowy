import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcut_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:mocktail/mocktail.dart';

class MockShortcutsCubit extends MockCubit<ShortcutsState>
    implements ShortcutsCubit {}

void main() {
  group(
    "CustomizeShortcutsView",
    () {
      group(
        "should be displayed in ViewState",
        () {
          late ShortcutsCubit mockShortcutsCubit;

          setUp(() {
            mockShortcutsCubit = MockShortcutsCubit();
          });

          testWidgets('Initial when cubit emits [ShortcutsStatus.Initial]',
              (widgetTester) async {
            when(() => mockShortcutsCubit.state)
                .thenReturn(const ShortcutsState());

            await widgetTester.pumpWidget(
              BlocProvider.value(
                value: mockShortcutsCubit,
                child:
                    const MaterialApp(home: SettingsCustomizeShortcutsView()),
              ),
            );
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
          });

          testWidgets(
            'Updating when cubit emits [ShortcutsStatus.updating]',
            (widgetTester) async {
              when(() => mockShortcutsCubit.state).thenReturn(
                  const ShortcutsState(status: ShortcutsStatus.updating));

              await widgetTester.pumpWidget(
                BlocProvider.value(
                  value: mockShortcutsCubit,
                  child:
                      const MaterialApp(home: SettingsCustomizeShortcutsView()),
                ),
              );
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
            },
          );

          testWidgets(
            'Shows ShortcutsList when cubit emits [ShortcutsStatus.success]',
            (widgetTester) async {
              KeyEventResult dummyHandler(EditorState e, RawKeyEvent? r) =>
                  KeyEventResult.handled;

              final dummyShortcuts = <ShortcutEvent>[
                ShortcutEvent(
                    key: 'Copy', command: 'ctrl+c', handler: dummyHandler),
                ShortcutEvent(
                    key: 'Paste', command: 'ctrl+v', handler: dummyHandler),
                ShortcutEvent(
                    key: 'Undo', command: 'ctrl+z', handler: dummyHandler),
                ShortcutEvent(
                    key: 'Redo', command: 'ctrl+y', handler: dummyHandler),
              ];

              when(() => mockShortcutsCubit.state).thenReturn(
                ShortcutsState(
                  status: ShortcutsStatus.success,
                  shortcuts: dummyShortcuts,
                ),
              );
              await widgetTester.pumpWidget(
                BlocProvider.value(
                  value: mockShortcutsCubit,
                  child:
                      const MaterialApp(home: SettingsCustomizeShortcutsView()),
                ),
              );

              await widgetTester.pump();

              final listViewFinder = find.byType(ShortcutsListView);
              final foundShortcuts = widgetTester
                  .widget<ShortcutsListView>(listViewFinder)
                  .shortcuts;

              expect(listViewFinder, findsOneWidget);
              expect(foundShortcuts, dummyShortcuts);
            },
          );

          testWidgets('Shows Error when cubit emits [ShortcutsStatus.failure]',
              (tester) async {
            when(() => mockShortcutsCubit.state).thenReturn(
              const ShortcutsState(
                status: ShortcutsStatus.failure,
              ),
            );
            await tester.pumpWidget(
              BlocProvider.value(
                value: mockShortcutsCubit,
                child:
                    const MaterialApp(home: SettingsCustomizeShortcutsView()),
              ),
            );
            expect(find.byType(ShortcutsErrorView), findsOneWidget);
          });
        },
      );
    },
  );
}
