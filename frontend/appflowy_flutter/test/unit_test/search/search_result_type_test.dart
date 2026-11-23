import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final views = [
    ViewPB(id: 'grid', layout: ViewLayoutPB.Grid),
    ViewPB(id: 'doc', layout: ViewLayoutPB.Document),
    ViewPB(
      id: 'space',
      layout: ViewLayoutPB.Document,
      extra: '{"is_space":true}',
    ),
    ViewPB(id: 'board', layout: ViewLayoutPB.Board),
    ViewPB(id: 'chat', layout: ViewLayoutPB.Chat),
    ViewPB(id: 'calendar', layout: ViewLayoutPB.Calendar),
  ];
  final results = <String, SearchResultItem>{
    for (final id in [...views.map((view) => view.id), 'uncached'])
      id: SearchResultItem(
        id: id,
        icon: ResultIconPB(),
        content: '',
        displayName: id,
      ),
  };

  final state = CommandPaletteState.initial().copyWith(
    cachedViews: {for (final view in views) view.id: view},
    combinedResponseItems: results,
  );

  Iterable<String> resultIds(
          CommandPaletteState state, SearchResultType type) =>
      state.visibleResults(type).map((item) => item.id);

  test('all types keeps the existing order and excludes unavailable views', () {
    expect(resultIds(state, SearchResultType.all), [
      'grid',
      'doc',
      'space',
      'board',
      'chat',
      'calendar',
    ]);
  });

  test('documents excludes spaces, databases, and chat pages', () {
    expect(resultIds(state, SearchResultType.documents), ['doc']);
  });

  test('databases includes grid, board, and calendar in result order', () {
    expect(resultIds(state, SearchResultType.databases), [
      'grid',
      'board',
      'calendar',
    ]);
  });

  test('all types preserves results while view metadata loads', () {
    final stateWithoutViews = state.copyWith(cachedViews: {});
    expect(resultIds(stateWithoutViews, SearchResultType.all), results.keys);
    expect(resultIds(stateWithoutViews, SearchResultType.documents), isEmpty);
    expect(resultIds(stateWithoutViews, SearchResultType.databases), isEmpty);
  });
}
