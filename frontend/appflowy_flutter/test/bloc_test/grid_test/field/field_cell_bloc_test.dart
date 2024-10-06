import 'package:appflowy/plugins/database/application/field/field_cell_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('field cell bloc:', () {
    late GridTestContext context;
    late double width;

    setUp(() async {
      context = await gridTest.makeDefaultTestGrid();
    });

    blocTest(
      'update field width',
      build: () => FieldCellBloc(
        fieldInfo: context.fieldController.fieldInfos[0],
        viewId: context.view.id,
      ),
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
      'field width should not be less than 50px',
      build: () => FieldCellBloc(
        viewId: context.view.id,
        fieldInfo: context.fieldController.fieldInfos[0],
      ),
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
