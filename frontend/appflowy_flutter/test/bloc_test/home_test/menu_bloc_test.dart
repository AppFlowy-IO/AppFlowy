import 'package:appflowy/workspace/application/menu/sidebar_root_views_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('assert initial apps is the build-in app', () async {
    final menuBloc = SidebarRootViewsBloc()
      ..add(
        SidebarRootViewsEvent.initial(
          testContext.userProfile,
          testContext.currentWorkspace.id,
        ),
      );

    await blocResponseFuture();

    assert(menuBloc.state.views.length == 1);
  });

  test('reorder apps', () async {
    final menuBloc = SidebarRootViewsBloc()
      ..add(
        SidebarRootViewsEvent.initial(
          testContext.userProfile,
          testContext.currentWorkspace.id,
        ),
      );
    await blocResponseFuture();
    menuBloc.add(const SidebarRootViewsEvent.createRootView("App 1"));
    await blocResponseFuture();
    menuBloc.add(const SidebarRootViewsEvent.createRootView("App 2"));
    await blocResponseFuture();
    menuBloc.add(const SidebarRootViewsEvent.createRootView("App 3"));
    await blocResponseFuture();

    assert(menuBloc.state.views[1].name == 'App 1');
    assert(menuBloc.state.views[2].name == 'App 2');
    assert(menuBloc.state.views[3].name == 'App 3');
  });
}
