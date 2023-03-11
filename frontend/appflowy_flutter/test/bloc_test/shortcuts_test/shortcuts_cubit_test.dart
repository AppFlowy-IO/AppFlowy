// ignore_for_file: prefer_const_constructors
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcut_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shortcuts Cubit', () {
    test('state supports value comparison', () {
      expect(ShortcutsState(), ShortcutsState());
      expect(
          ShortcutsState(
                status: ShortcutsStatus.initial,
              ) !=
              ShortcutsState(
                status: ShortcutsStatus.success,
              ),
          true);
    });

    test(
      "cubit initialized properly",
      () {
        expect(ShortcutsCubit().state.status, ShortcutsStatus.initial);
        expect(ShortcutsCubit().state.shortcuts, const <ShortcutEvent>[]);
      },
    );

    group(
      "fetch shortcuts",
      () {
        blocTest<ShortcutsCubit, ShortcutsState>(
          'emits [ShortcutsState.status = success] when shortcuts are loaded',
          build: () => ShortcutsCubit(),
          act: (cubit) => cubit.fetchShortcuts(),
          expect: () => <ShortcutsState>[
            ShortcutsState(
                shortcuts: builtInShortcutEvents,
                status: ShortcutsStatus.success),
          ],
        );
      },
    );
  });
}
