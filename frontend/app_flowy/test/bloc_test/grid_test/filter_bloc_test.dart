import 'package:app_flowy/plugins/grid/application/filter/filter_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('$GridFilterBloc', () {
    setUp(() async {
      await gridTest.createTestGrid();
    });
    blocTest<GridFilterBloc, GridFilterState>(
      "create a text filter",
      build: () => GridFilterBloc(viewId: gridTest.gridView.id)
        ..add(const GridFilterEvent.initial()),
      act: (bloc) async {
        final textField = gridTest.textFieldContext();
        bloc.add(
          GridFilterEvent.createTextFilter(
              fieldId: textField.id,
              condition: TextFilterCondition.TextIsEmpty,
              content: ""),
        );
      },
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        assert(bloc.state.filters.length == 1);
      },
    );

    blocTest<GridFilterBloc, GridFilterState>(
      "delete a text filter",
      build: () => GridFilterBloc(viewId: gridTest.gridView.id)
        ..add(const GridFilterEvent.initial()),
      act: (bloc) async {
        final textField = gridTest.textFieldContext();
        bloc.add(
          GridFilterEvent.createTextFilter(
              fieldId: textField.id,
              condition: TextFilterCondition.TextIsEmpty,
              content: ""),
        );
        await gridResponseFuture();
        final filter = bloc.state.filters.first;
        bloc.add(
          GridFilterEvent.deleteFilter(
            fieldId: textField.id,
            filterId: filter.id,
            fieldType: textField.fieldType,
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        assert(bloc.state.filters.isEmpty);
      },
    );
  });
}
