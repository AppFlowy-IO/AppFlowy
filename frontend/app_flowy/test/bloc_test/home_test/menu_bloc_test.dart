import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('assert initial apps is the build-in app', () async {
    final menuBloc = MenuBloc(
      user: testContext.userProfile,
      workspace: testContext.currentWorkspace,
    )..add(const MenuEvent.initial());
    await blocResponseFuture();

    assert(menuBloc.state.apps.length == 1);
  });

  test('reorder apps', () async {
    final menuBloc = MenuBloc(
      user: testContext.userProfile,
      workspace: testContext.currentWorkspace,
    )..add(const MenuEvent.initial());
    await blocResponseFuture();
    menuBloc.add(const MenuEvent.createApp("App 1"));
    await blocResponseFuture();
    menuBloc.add(const MenuEvent.createApp("App 2"));
    await blocResponseFuture();
    menuBloc.add(const MenuEvent.createApp("App 3"));
    await blocResponseFuture();

    menuBloc.add(const MenuEvent.moveApp(1, 3));
    await blocResponseFuture();

    assert(menuBloc.state.apps[1].name == 'App 2');
    assert(menuBloc.state.apps[2].name == 'App 3');
    assert(menuBloc.state.apps[3].name == 'App 1');
  });
}
