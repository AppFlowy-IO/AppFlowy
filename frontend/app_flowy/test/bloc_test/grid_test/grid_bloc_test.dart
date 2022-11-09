import 'package:app_flowy/plugins/grid/application/grid_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
    await gridTest.createTestGrid();
  });

  group('Create a new row in Grid', () {
    blocTest<GridBloc, GridState>(
      "Create a row",
      build: () =>
          GridBloc(view: gridTest.gridView)..add(const GridEvent.initial()),
      act: (bloc) => bloc.add(const GridEvent.createRow()),
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        assert(bloc.state.rowInfos.length == 4);
      },
    );
  });

  group('Delete a row in the grid', () {
    late GridBloc gridBloc;
    setUpAll(() async {
      gridBloc = GridBloc(view: gridTest.gridView)
        ..add(const GridEvent.initial());
      await gridResponseFuture();
    });

    test('delete the last row', () async {
      gridBloc.add(GridEvent.deleteRow(gridBloc.state.rowInfos.last));
      await gridResponseFuture();
      assert(gridBloc.state.rowInfos.length == 3);
    });
  });
}
