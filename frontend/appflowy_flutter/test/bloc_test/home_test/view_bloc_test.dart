import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  const name = 'Hello world';

  late AppFlowyUnitTest testContext;

  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  Future<ViewBloc> createTestViewBloc() async {
    final view = await testContext.createWorkspace();
    final viewBloc = ViewBloc(view: view)
      ..add(
        const ViewEvent.initial(),
      );
    await blocResponseFuture();
    return viewBloc;
  }

  test('rename view test', () async {
    final viewBloc = await createTestViewBloc();
    viewBloc.add(const ViewEvent.rename(name));
    await blocResponseFuture();
    expect(viewBloc.state.view.name, name);
  });

  test('duplicate view test', () async {
    final viewBloc = await createTestViewBloc();
    // create a nested view
    viewBloc.add(
      const ViewEvent.createView(
        name,
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    expect(viewBloc.state.view.childViews.length, 1);
    final childViewBloc = ViewBloc(view: viewBloc.state.view.childViews.first)
      ..add(
        const ViewEvent.initial(),
      );
    childViewBloc.add(const ViewEvent.duplicate());
    await blocResponseFuture(millisecond: 1000);
    expect(viewBloc.state.view.childViews.length, 2);
  });

  test('delete view test', () async {
    final viewBloc = await createTestViewBloc();
    viewBloc.add(
      const ViewEvent.createView(
        name,
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    expect(viewBloc.state.view.childViews.length, 1);
    final childViewBloc = ViewBloc(view: viewBloc.state.view.childViews.first)
      ..add(
        const ViewEvent.initial(),
      );
    await blocResponseFuture();
    childViewBloc.add(const ViewEvent.delete());
    await blocResponseFuture();
    assert(viewBloc.state.view.childViews.isEmpty);
  });

  test('create nested view test', () async {
    final viewBloc = await createTestViewBloc();
    viewBloc.add(
      const ViewEvent.createView(
        'Document 1',
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    final document1Bloc = ViewBloc(view: viewBloc.state.view.childViews.first)
      ..add(
        const ViewEvent.initial(),
      );
    await blocResponseFuture();
    const name = 'Document 1 - 1';
    document1Bloc.add(
      const ViewEvent.createView(
        'Document 1 - 1',
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    expect(document1Bloc.state.view.childViews.length, 1);
    expect(document1Bloc.state.view.childViews.first.name, name);
  });

  test('create documents in order', () async {
    final viewBloc = await createTestViewBloc();
    final names = ['1', '2', '3'];
    for (final name in names) {
      viewBloc.add(
        ViewEvent.createView(
          name,
          ViewLayoutPB.Document,
          section: ViewSectionPB.Public,
        ),
      );
      await blocResponseFuture(millisecond: 400);
    }

    expect(viewBloc.state.view.childViews.length, 3);
    for (var i = 0; i < names.length; i++) {
      expect(viewBloc.state.view.childViews[i].name, names[i]);
    }
  });

  test('open latest view test', () async {
    final viewBloc = await createTestViewBloc();
    expect(viewBloc.state.lastCreatedView, isNull);

    viewBloc.add(
      const ViewEvent.createView(
        '1',
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    expect(
      viewBloc.state.lastCreatedView!.id,
      viewBloc.state.view.childViews.last.id,
    );
    expect(
      viewBloc.state.lastCreatedView!.name,
      '1',
    );

    viewBloc.add(
      const ViewEvent.createView(
        '2',
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    expect(
      viewBloc.state.lastCreatedView!.name,
      '2',
    );
  });

  test('open latest document test', () async {
    const name1 = 'document';
    final viewBloc = await createTestViewBloc();
    viewBloc.add(
      const ViewEvent.createView(
        name1,
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    final document = viewBloc.state.lastCreatedView!;
    assert(document.name == name1);

    const gird = 'grid';
    viewBloc.add(
      const ViewEvent.createView(
        gird,
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();
    assert(viewBloc.state.lastCreatedView!.name == gird);

    var workspaceSetting =
        await FolderEventGetCurrentWorkspaceSetting().send().then(
              (result) => result.fold(
                (l) => l,
                (r) => throw Exception(),
              ),
            );
    workspaceSetting.latestView.id == viewBloc.state.lastCreatedView!.id;

    // ignore: unused_local_variable
    final documentBloc = DocumentBloc(view: document)
      ..add(
        const DocumentEvent.initial(),
      );
    await blocResponseFuture();

    workspaceSetting =
        await FolderEventGetCurrentWorkspaceSetting().send().then(
              (result) => result.fold(
                (l) => l,
                (r) => throw Exception(),
              ),
            );
    workspaceSetting.latestView.id == document.id;
  });

  test('create views', () async {
    final viewBloc = await createTestViewBloc();
    const layouts = ViewLayoutPB.values;
    for (var i = 0; i < layouts.length; i++) {
      final layout = layouts[i];
      viewBloc.add(
        ViewEvent.createView(
          'Test $layout',
          layout,
          section: ViewSectionPB.Public,
        ),
      );
      await blocResponseFuture(millisecond: 1000);
      expect(viewBloc.state.view.childViews.length, i + 1);
      expect(viewBloc.state.view.childViews.last.name, 'Test $layout');
      expect(viewBloc.state.view.childViews.last.layout, layout);
    }
  });
}
