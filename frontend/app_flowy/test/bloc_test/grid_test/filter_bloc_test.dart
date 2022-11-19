import 'package:app_flowy/plugins/grid/application/filter/filter_bloc.dart';
import 'package:app_flowy/plugins/grid/application/grid_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbenum.dart';
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
    late GridTestContext context;
    setUp(() async {
      context = await gridTest.createTestGrid();
    });

    blocTest<GridFilterBloc, GridFilterState>(
      "create a text filter",
      build: () => GridFilterBloc(viewId: context.gridView.id)
        ..add(const GridFilterEvent.initial()),
      act: (bloc) async {
        final textField = context.textFieldContext();
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
      build: () => GridFilterBloc(viewId: context.gridView.id)
        ..add(const GridFilterEvent.initial()),
      act: (bloc) async {
        final textField = context.textFieldContext();
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

  test('filter rows with condition: text is empty', () async {
    final context = await gridTest.createTestGrid();
    final filterBloc = GridFilterBloc(viewId: context.gridView.id)
      ..add(const GridFilterEvent.initial());
    final gridBloc = GridBloc(view: context.gridView)
      ..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    filterBloc.add(
      GridFilterEvent.createTextFilter(
          fieldId: textField.id,
          condition: TextFilterCondition.TextIsEmpty,
          content: ""),
    );
    await gridResponseFuture();

    assert(gridBloc.state.rowInfos.length == 3);
  });

  test('filter rows with condition: text is empty(After edit the row)',
      () async {
    final context = await gridTest.createTestGrid();
    final filterBloc = GridFilterBloc(viewId: context.gridView.id)
      ..add(const GridFilterEvent.initial());

    final gridBloc = GridBloc(view: context.gridView)
      ..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    filterBloc.add(
      GridFilterEvent.createTextFilter(
          fieldId: textField.id,
          condition: TextFilterCondition.TextIsEmpty,
          content: ""),
    );
    await gridResponseFuture();

    final controller = await context.makeTextCellController();
    controller.saveCellData("edit text cell content");
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.length == 2);

    controller.saveCellData("");
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.length == 3);
  });

  test('filter rows with condition: text is not empty', () async {
    final context = await gridTest.createTestGrid();
    final filterBloc = GridFilterBloc(viewId: context.gridView.id)
      ..add(const GridFilterEvent.initial());

    final textField = context.textFieldContext();
    await gridResponseFuture();
    filterBloc.add(
      GridFilterEvent.createTextFilter(
          fieldId: textField.id,
          condition: TextFilterCondition.TextIsNotEmpty,
          content: ""),
    );
    await gridResponseFuture();
    assert(context.rowInfos.isEmpty);
  });

  test('filter rows with condition: checkbox uncheck', () async {
    final context = await gridTest.createTestGrid();
    final checkboxField = context.checkboxFieldContext();
    final filterBloc = GridFilterBloc(viewId: context.gridView.id)
      ..add(const GridFilterEvent.initial());
    final gridBloc = GridBloc(view: context.gridView)
      ..add(const GridEvent.initial());

    await gridResponseFuture();
    filterBloc.add(
      GridFilterEvent.createCheckboxFilter(
        fieldId: checkboxField.id,
        condition: CheckboxFilterCondition.IsUnChecked,
      ),
    );
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.length == 3);
  });

  test('filter rows with condition: checkbox check', () async {
    final context = await gridTest.createTestGrid();
    final checkboxField = context.checkboxFieldContext();
    final filterBloc = GridFilterBloc(viewId: context.gridView.id)
      ..add(const GridFilterEvent.initial());
    final gridBloc = GridBloc(view: context.gridView)
      ..add(const GridEvent.initial());

    await gridResponseFuture();
    filterBloc.add(
      GridFilterEvent.createCheckboxFilter(
        fieldId: checkboxField.id,
        condition: CheckboxFilterCondition.IsChecked,
      ),
    );
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.isEmpty);
  });
}
