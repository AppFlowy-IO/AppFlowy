import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('Edit Grid:', () {
    late GridTestContext context;

    setUp(() async {
      context = await gridTest.makeDefaultTestGrid();
    });

    // The initial number of rows is 3 for each grid
    // We create one row so we expect 4 rows
    blocTest<GridBloc, GridState>(
      "create a row",
      build: () => GridBloc(
        view: context.view,
        databaseController: DatabaseController(view: context.view),
      )..add(const GridEvent.initial()),
      act: (bloc) => bloc.add(const GridEvent.createRow()),
      wait: gridResponseDuration(),
      verify: (bloc) {
        expect(bloc.state.rowInfos.length, equals(4));
      },
    );

    blocTest<GridBloc, GridState>(
      "delete the last row",
      build: () => GridBloc(
        view: context.view,
        databaseController: DatabaseController(view: context.view),
      )..add(const GridEvent.initial()),
      act: (bloc) async {
        await gridResponseFuture();
        bloc.add(GridEvent.deleteRow(bloc.state.rowInfos.last));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        expect(bloc.state.rowInfos.length, equals(2));
      },
    );

    String? firstId;
    String? secondId;
    String? thirdId;

    blocTest(
      'reorder rows',
      build: () => GridBloc(
        view: context.view,
        databaseController: DatabaseController(view: context.view),
      )..add(const GridEvent.initial()),
      act: (bloc) async {
        await gridResponseFuture();

        firstId = bloc.state.rowInfos[0].rowId;
        secondId = bloc.state.rowInfos[1].rowId;
        thirdId = bloc.state.rowInfos[2].rowId;

        bloc.add(const GridEvent.moveRow(0, 2));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        expect(secondId, equals(bloc.state.rowInfos[0].rowId));
        expect(thirdId, equals(bloc.state.rowInfos[1].rowId));
        expect(firstId, equals(bloc.state.rowInfos[2].rowId));
      },
    );
  });
}
