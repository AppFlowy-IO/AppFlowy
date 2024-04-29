import 'package:flutter/material.dart';

import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
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
                child: const MaterialApp(home: SettingsShortcutsView()),
              ),
            );
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
          });

          testWidgets(
            'Updating when cubit emits [ShortcutsStatus.updating]',
            (widgetTester) async {
              when(() => mockShortcutsCubit.state).thenReturn(
                const ShortcutsState(status: ShortcutsStatus.updating),
              );

              await widgetTester.pumpWidget(
                BlocProvider.value(
                  value: mockShortcutsCubit,
                  child: const MaterialApp(home: SettingsShortcutsView()),
                ),
              );
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
            },
          );

          testWidgets(
            'Shows ShortcutsList when cubit emits [ShortcutsStatus.success]',
            (widgetTester) async {
              KeyEventResult dummyHandler(EditorState e) =>
                  KeyEventResult.handled;

              final dummyShortcuts = <CommandShortcutEvent>[
                CommandShortcutEvent(
                  key: 'Copy',
                  getDescription: () => 'Copy',
                  command: 'ctrl+c',
                  handler: dummyHandler,
                ),
                CommandShortcutEvent(
                  key: 'Paste',
                  getDescription: () => 'Paste',
                  command: 'ctrl+v',
                  handler: dummyHandler,
                ),
                CommandShortcutEvent(
                  key: 'Undo',
                  getDescription: () => 'Undo',
                  command: 'ctrl+z',
                  handler: dummyHandler,
                ),
                CommandShortcutEvent(
                  key: 'Redo',
                  getDescription: () => 'Redo',
                  command: 'ctrl+y',
                  handler: dummyHandler,
                ),
              ];

              when(() => mockShortcutsCubit.state).thenReturn(
                ShortcutsState(
                  status: ShortcutsStatus.success,
                  commandShortcutEvents: dummyShortcuts,
                ),
              );
              await widgetTester.pumpWidget(
                BlocProvider.value(
                  value: mockShortcutsCubit,
                  child: const MaterialApp(home: SettingsShortcutsView()),
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
                child: const MaterialApp(home: SettingsShortcutsView()),
              ),
            );
            expect(find.byType(ShortcutsErrorView), findsOneWidget);
          });
        },
      );
    },
  );
}
