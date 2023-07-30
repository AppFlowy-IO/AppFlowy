import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('rename view test', () async {
    final app = await testContext.createTestApp();

    final appBloc = AppBloc(view: app)..add(const AppEvent.initial());
    appBloc.add(
      const AppEvent.createView("Test document", ViewLayoutPB.Document),
    );

    await blocResponseFuture();

    final viewBloc = ViewBloc(view: appBloc.state.views.first)
      ..add(const ViewEvent.initial());
    viewBloc.add(const ViewEvent.rename('Hello world'));
    await blocResponseFuture();

    assert(viewBloc.state.view.name == "Hello world");
  });

  test('duplicate view test', () async {
    final app = await testContext.createTestApp();
    final appBloc = AppBloc(view: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    appBloc.add(
      const AppEvent.createView("Test document", ViewLayoutPB.Document),
    );
    await blocResponseFuture();

    final viewBloc = ViewBloc(view: appBloc.state.views.first)
      ..add(const ViewEvent.initial());
    await blocResponseFuture();

    viewBloc.add(const ViewEvent.duplicate());
    await blocResponseFuture();

    expect(appBloc.state.views.length, 2);
  });

  test('delete view test', () async {
    final app = await testContext.createTestApp();
    final appBloc = AppBloc(view: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    appBloc.add(
      const AppEvent.createView("Test document", ViewLayoutPB.Document),
    );
    await blocResponseFuture();
    expect(appBloc.state.views.length, 1);

    final viewBloc = ViewBloc(view: appBloc.state.views.first)
      ..add(const ViewEvent.initial());
    await blocResponseFuture();

    viewBloc.add(const ViewEvent.delete());
    await blocResponseFuture();

    assert(appBloc.state.views.isEmpty);
  });

  test('create nested view test', () async {
    final app = await testContext.createTestApp();

    final appBloc = AppBloc(view: app);
    appBloc
      ..add(
        const AppEvent.initial(),
      )
      ..add(
        const AppEvent.createView('Document 1', ViewLayoutPB.Document),
      );
    await blocResponseFuture();

    // create a nested view
    const name = 'Document 1 - 1';
    final viewBloc = ViewBloc(view: appBloc.state.views.first);
    viewBloc
      ..add(
        const ViewEvent.initial(),
      )
      ..add(
        const ViewEvent.createView(name, ViewLayoutPB.Document),
      );
    await blocResponseFuture();

    assert(viewBloc.state.childViews.first.name == name);
  });
}
