import 'dart:ffi';

import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/custom_cut_command.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_cubit.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:mocktail/mocktail.dart';

class MockSettingsShortcutService extends Mock
    implements SettingsShortcutService {}

void main() {
  group("ShortcutsCubit", () {
    late SettingsShortcutService service;
    late ShortcutsCubit shortcutsCubit;

    setUp(() async {
      service = MockSettingsShortcutService();

      when(
        () => service.saveAllShortcuts(any()),
      ).thenAnswer((_) async => true);
      when(
        () => service.getCustomizeShortcuts(),
      ).thenAnswer((_) async => []);
      when(
        () => service.updateCommandShortcuts(any(), any()),
      ).thenAnswer((_) async => Void);

      shortcutsCubit = ShortcutsCubit(service);
    });

    test('initial state is correct', () {
      final shortcutsCubit = ShortcutsCubit(service);
      expect(shortcutsCubit.state, const ShortcutsState());
    });

    group('fetchShortcuts', () {
      blocTest<ShortcutsCubit, ShortcutsState>(
        'calls getCustomizeShortcuts() once',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.fetchShortcuts(),
        verify: (_) {
          verify(() => service.getCustomizeShortcuts()).called(1);
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, failure] when getCustomizeShortcuts() throws',
        setUp: () {
          when(
            () => service.getCustomizeShortcuts(),
          ).thenThrow(Exception('oops'));
        },
        build: () => shortcutsCubit,
        act: (cubit) => cubit.fetchShortcuts(),
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.failure),
        ],
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, success] when getCustomizeShortcuts() returns shortcuts',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.fetchShortcuts(),
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.success)
              .having(
                (w) => w.commandShortcutEvents,
                'shortcuts',
                commandShortcutEvents,
              ),
        ],
      );
    });

    group('updateShortcut', () {
      blocTest<ShortcutsCubit, ShortcutsState>(
        'calls saveAllShortcuts() once',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.updateAllShortcuts(),
        verify: (_) {
          verify(() => service.saveAllShortcuts(any())).called(1);
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, failure] when saveAllShortcuts() throws',
        setUp: () {
          when(
            () => service.saveAllShortcuts(any()),
          ).thenThrow(Exception('oops'));
        },
        build: () => shortcutsCubit,
        act: (cubit) => cubit.updateAllShortcuts(),
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.failure),
        ],
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, success] when saveAllShortcuts() is successful',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.updateAllShortcuts(),
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.success),
        ],
      );
    });

    group('resetToDefault', () {
      blocTest<ShortcutsCubit, ShortcutsState>(
        'calls saveAllShortcuts() once',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.resetToDefault(),
        verify: (_) {
          verify(() => service.saveAllShortcuts(any())).called(1);
          verify(() => service.getCustomizeShortcuts()).called(1);
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, failure] when saveAllShortcuts() throws',
        setUp: () {
          when(
            () => service.saveAllShortcuts(any()),
          ).thenThrow(Exception('oops'));
        },
        build: () => shortcutsCubit,
        act: (cubit) => cubit.resetToDefault(),
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.failure),
        ],
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, success] when getCustomizeShortcuts() returns shortcuts',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.resetToDefault(),
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.success)
              .having(
                (w) => w.commandShortcutEvents,
                'shortcuts',
                commandShortcutEvents,
              ),
        ],
      );
    });

    group('resetIndividualShortcut', () {
      final dummyShortcut = CommandShortcutEvent(
        key: 'dummy key event',
        command: 'ctrl+alt+shift+arrow up',
        handler: (_) {
          return KeyEventResult.handled;
        },
        getDescription: () => 'dummy key event',
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'does not call saveAllShortcuts() since dummyShortcut is not in defaultShortcuts',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.resetIndividualShortcut(dummyShortcut),
        verify: (_) {
          verifyNever(() => service.saveAllShortcuts(any()));
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'does not call saveAllShortcuts() when resetIndividualShortcut called redundantly',
        build: () => shortcutsCubit,
        // here we are using customCutCommand since it is a part of defaultShortcuts
        act: (cubit) => cubit.resetIndividualShortcut(customCutCommand),
        verify: (_) {
          verifyNever(() => service.saveAllShortcuts(any()));
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'calls saveAllShortcuts() once for shortcuts in defaultShortcuts',
        build: () => shortcutsCubit,
        // here we are using customCutCommand since it is a part of defaultShortcuts
        // we have to override it, inorder to reset it.
        act: (cubit) {
          customCutCommand.updateCommand(command: 'ctrl+alt+shift+x');
          cubit.resetIndividualShortcut(customCutCommand);
        },
        verify: (_) {
          verify(() => service.saveAllShortcuts(any())).called(1);
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, failure] when saveAllShortcuts() throws',
        setUp: () {
          when(
            () => service.saveAllShortcuts(any()),
          ).thenThrow(Exception('oops'));
        },
        build: () => shortcutsCubit,
        act: (cubit) {
          customCutCommand.updateCommand(command: 'ctrl+alt+shift+x');
          cubit.resetIndividualShortcut(customCutCommand);
        },
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.failure),
        ],
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, failure] when shortcut not found in defaultShortcuts',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.resetIndividualShortcut(dummyShortcut),
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.failure),
        ],
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, success] when succesfully updates shortcut',
        build: () => shortcutsCubit,
        act: (cubit) {
          customCutCommand.updateCommand(command: 'ctrl+alt+shift+x');
          cubit.resetIndividualShortcut(customCutCommand);
        },
        expect: () => <dynamic>[
          const ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.success),
        ],
      );
    });
  });
}
