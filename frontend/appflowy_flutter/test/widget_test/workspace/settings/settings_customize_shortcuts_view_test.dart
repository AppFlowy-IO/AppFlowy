import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcut_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../bloc_test/grid_test/util.dart';

class MockShortcutsCubit extends MockCubit<ShortcutsState>
    implements ShortcutsCubit {}

void main() {
  setUpAll(() {
    AppFlowyGridTest.ensureInitialized();
  });

  Widget widgetUnderTest({required ShortcutsCubit cubit}) {
    return MaterialApp(
        home: BlocProvider<ShortcutsCubit>(
      create: (context) => cubit,
      child: const SettingsCustomizeShortcuts(),
    ));
  }

  group(
    "settings customize shortcuts widget test",
    () {
      late ShortcutsCubit mockShortcutsCubit;
      setUp(() {
        mockShortcutsCubit = MockShortcutsCubit();
      });
    },
  );
}
