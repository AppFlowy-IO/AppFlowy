import 'package:app_flowy/plugins/grid/application/filter/filter_bloc.dart';
import 'package:app_flowy/plugins/grid/application/grid_bloc.dart';
import 'package:app_flowy/plugins/grid/application/grid_data_controller.dart';
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

  group('$GridFilterEditBloc', () {
    late GridTestContext context;
    setUp(() async {
      context = await gridTest.createTestGrid();
    });

    blocTest<GridFilterEditBloc, GridFilterEditState>(
      "create a text filter",
      build: () => GridFilterEditBloc(
        viewId: context.gridView.id,
        fieldController: context.fieldController,
      )..add(const GridFilterEditEvent.initial()),
      act: (bloc) async {
        final textField = context.textFieldContext();
        bloc.add(
          GridFilterEditEvent.createTextFilter(
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

    blocTest<GridFilterEditBloc, GridFilterEditState>(
      "delete a text filter",
      build: () => GridFilterEditBloc(
        viewId: context.gridView.id,
        fieldController: context.fieldController,
      )..add(const GridFilterEditEvent.initial()),
      act: (bloc) async {
        final textField = context.textFieldContext();
        bloc.add(
          GridFilterEditEvent.createTextFilter(
              fieldId: textField.id,
              condition: TextFilterCondition.TextIsEmpty,
              content: ""),
        );
        await gridResponseFuture();
        final filter = bloc.state.filters.first;
        bloc.add(
          GridFilterEditEvent.deleteFilter(
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
    final filterBloc = GridFilterEditBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    )..add(const GridFilterEditEvent.initial());
    final dataController = GridDataController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      dataController: dataController,
    )..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    filterBloc.add(
      GridFilterEditEvent.createTextFilter(
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
    final filterBloc = GridFilterEditBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    )..add(const GridFilterEditEvent.initial());
    final dataController = GridDataController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      dataController: dataController,
    )..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    filterBloc.add(
      GridFilterEditEvent.createTextFilter(
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
    final filterBloc = GridFilterEditBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    )..add(const GridFilterEditEvent.initial());

    final textField = context.textFieldContext();
    await gridResponseFuture();
    filterBloc.add(
      GridFilterEditEvent.createTextFilter(
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
    final filterBloc = GridFilterEditBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    )..add(const GridFilterEditEvent.initial());
    final dataController = GridDataController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      dataController: dataController,
    )..add(const GridEvent.initial());

    await gridResponseFuture();
    filterBloc.add(
      GridFilterEditEvent.createCheckboxFilter(
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
    final filterBloc = GridFilterEditBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    )..add(const GridFilterEditEvent.initial());
    final dataController = GridDataController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      dataController: dataController,
    )..add(const GridEvent.initial());

    await gridResponseFuture();
    filterBloc.add(
      GridFilterEditEvent.createCheckboxFilter(
        fieldId: checkboxField.id,
        condition: CheckboxFilterCondition.IsChecked,
      ),
    );
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.isEmpty);
  });
}
