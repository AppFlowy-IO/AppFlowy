import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest test;
  setUpAll(() async {
    test = await AppFlowyUnitTest.ensureInitialized();
  });

  group('$MenuBloc', () {
    late MenuBloc menuBloc;
    setUp(() async {
      menuBloc = MenuBloc(
        user: test.userProfile,
        workspace: test.currentWorkspace,
      )..add(const MenuEvent.initial());

      await blocResponseFuture();
    });
    blocTest<MenuBloc, MenuState>(
      "assert initial apps is the build-in app",
      build: () => menuBloc,
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.apps.length == 1);
      },
    );
    //
    blocTest<MenuBloc, MenuState>(
      "create apps",
      build: () => menuBloc,
      act: (bloc) async {
        bloc.add(const MenuEvent.createApp("App 1"));
        bloc.add(const MenuEvent.createApp("App 2"));
        bloc.add(const MenuEvent.createApp("App 3"));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        // apps[0] is the build-in app
        assert(bloc.state.apps[1].name == 'App 1');
        assert(bloc.state.apps[2].name == 'App 2');
        assert(bloc.state.apps[3].name == 'App 3');
      },
    );
    blocTest<MenuBloc, MenuState>(
      "reorder apps",
      build: () => menuBloc,
      act: (bloc) async {
        bloc.add(const MenuEvent.moveApp(1, 3));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.apps[1].name == 'App 2');
        assert(bloc.state.apps[2].name == 'App 3');
        assert(bloc.state.apps[3].name == 'App 1');
      },
    );
  });

  //
}
