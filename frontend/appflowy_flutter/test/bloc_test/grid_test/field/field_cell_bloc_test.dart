import 'package:appflowy/plugins/database_view/application/field/field_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('$FieldCellBloc', () {
    late GridTestContext context;
    late double width;

    setUp(() async {
      context = await gridTest.createTestGrid();
    });

    blocTest(
      'update field width',
      build: () => FieldCellBloc(
        cellContext: FieldContext(
          field: context.fieldContexts[0].field,
          viewId: context.gridView.id,
        ),
      )..add(const FieldCellEvent.initial()),
      act: (bloc) {
        width = bloc.state.width;
        bloc.add(const FieldCellEvent.onResizeStart());
        bloc.add(const FieldCellEvent.startUpdateWidth(100));
        bloc.add(const FieldCellEvent.endUpdateWidth());
      },
      verify: (bloc) {
        expect(bloc.state.width, width + 100);
      },
    );

    blocTest(
      'field width should not be lesser than 50px',
      build: () => FieldCellBloc(
        cellContext: FieldContext(
          field: context.fieldContexts[0].field,
          viewId: context.gridView.id,
        ),
      )..add(const FieldCellEvent.initial()),
      act: (bloc) {
        bloc.add(const FieldCellEvent.onResizeStart());
        bloc.add(const FieldCellEvent.startUpdateWidth(-110));
        bloc.add(const FieldCellEvent.endUpdateWidth());
      },
      verify: (bloc) {
        expect(bloc.state.width, 50);
      },
    );
  });
}
