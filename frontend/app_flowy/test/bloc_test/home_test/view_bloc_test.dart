import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('rename view test', () async {
    final app = await testContext.createTestApp();
    final appBloc = AppBloc(app: app)..add(const AppEvent.initial());
    appBloc.add(AppEvent.createView(
      "Test document",
      DocumentPluginBuilder(),
    ));
    await blocResponseFuture();

    final viewBloc = ViewBloc(view: appBloc.state.views.first)
      ..add(const ViewEvent.initial());
    viewBloc.add(const ViewEvent.rename('Hello world'));
    await blocResponseFuture();

    assert(viewBloc.state.view.name == "Hello world");
  });

  test('duplicate view test', () async {
    final app = await testContext.createTestApp();
    final appBloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    appBloc.add(AppEvent.createView(
      "Test document",
      DocumentPluginBuilder(),
    ));
    await blocResponseFuture();

    final viewBloc = ViewBloc(view: appBloc.state.views.first)
      ..add(const ViewEvent.initial());
    await blocResponseFuture();

    viewBloc.add(const ViewEvent.duplicate());
    await blocResponseFuture();

    assert(appBloc.state.views.length == 2);
  });

  test('delete view test', () async {
    final app = await testContext.createTestApp();
    final appBloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    appBloc.add(AppEvent.createView(
      "Test document",
      DocumentPluginBuilder(),
    ));
    await blocResponseFuture();
    assert(appBloc.state.views.length == 1);

    final viewBloc = ViewBloc(view: appBloc.state.views.first)
      ..add(const ViewEvent.initial());
    await blocResponseFuture();

    viewBloc.add(const ViewEvent.delete());
    await blocResponseFuture();

    assert(appBloc.state.views.isEmpty);
  });
}
