import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('assert initial apps is the build-in app', () async {
    final menuBloc = SidebarSectionsBloc()
      ..add(
        SidebarSectionsEvent.initial(
          testContext.userProfile,
          testContext.currentWorkspace.id,
        ),
      );

    await blocResponseFuture();

    assert(menuBloc.state.section.publicViews.length == 1);
    assert(menuBloc.state.section.privateViews.isEmpty);
  });

  test('create views', () async {
    final menuBloc = SidebarSectionsBloc()
      ..add(
        SidebarSectionsEvent.initial(
          testContext.userProfile,
          testContext.currentWorkspace.id,
        ),
      );
    await blocResponseFuture();

    final names = ['View 1', 'View 2', 'View 3'];
    for (final name in names) {
      menuBloc.add(
        SidebarSectionsEvent.createRootViewInSection(
          name: name,
          index: 0,
          viewSection: ViewSectionPB.Public,
        ),
      );
      await blocResponseFuture();
    }

    final reversedNames = names.reversed.toList();
    for (var i = 0; i < names.length; i++) {
      assert(
        menuBloc.state.section.publicViews[i].name == reversedNames[i],
      );
    }
  });
}
