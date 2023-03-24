// ignore_for_file: prefer_const_constructors
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcut_cubit.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show builtInShortcutEvents;
import 'package:bloc_test/bloc_test.dart';
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
        () => service.saveShortcuts(any()),
      ).thenAnswer((_) async => true);
      when(
        () => service.loadShortcuts(),
      ).thenAnswer((_) async => builtInShortcutEvents);

      shortcutsCubit = ShortcutsCubit(service);
    });

    test('initial state is correct', () {
      final shortcutsCubit = ShortcutsCubit(service);
      expect(shortcutsCubit.state, ShortcutsState());
    });

    group('fetchShortcuts', () {
      blocTest<ShortcutsCubit, ShortcutsState>(
        'calls loadShortcuts() once',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.fetchShortcuts(),
        verify: (_) {
          verify(() => service.loadShortcuts()).called(1);
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, failure] when loadShortcuts() throws',
        setUp: () {
          when(
            () => service.loadShortcuts(),
          ).thenThrow(Exception('oops'));
        },
        build: () => shortcutsCubit,
        act: (cubit) => cubit.fetchShortcuts(),
        expect: () => <ShortcutsState>[
          ShortcutsState(status: ShortcutsStatus.updating),
          ShortcutsState(status: ShortcutsStatus.failure),
        ],
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, success] when loadShortcuts() returns shortcuts',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.fetchShortcuts(),
        expect: () => <dynamic>[
          ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.success)
              .having(
                (w) => w.shortcuts,
                'shortcuts',
                builtInShortcutEvents,
              ),
        ],
      );
    });

    group('updateShortcut', () {
      blocTest<ShortcutsCubit, ShortcutsState>(
        'calls saveShortcuts() once',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.updateShortcuts(),
        verify: (_) {
          verify(() => service.saveShortcuts(any())).called(1);
        },
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, failure] when updateShortcuts() throws',
        setUp: () {
          when(
            () => service.saveShortcuts(any()),
          ).thenThrow(Exception('oops'));
        },
        build: () => shortcutsCubit,
        act: (cubit) => cubit.updateShortcuts(),
        expect: () => <ShortcutsState>[
          ShortcutsState(status: ShortcutsStatus.updating),
          ShortcutsState(status: ShortcutsStatus.failure),
        ],
      );

      blocTest<ShortcutsCubit, ShortcutsState>(
        'emits [updating, success] when updateShortcuts() is successful',
        build: () => shortcutsCubit,
        act: (cubit) => cubit.updateShortcuts(),
        expect: () => <dynamic>[
          ShortcutsState(status: ShortcutsStatus.updating),
          isA<ShortcutsState>()
              .having((w) => w.status, 'status', ShortcutsStatus.success)
        ],
      );
    });
  });
}
