import 'package:app_flowy/plugins/grid/application/filter/filter_service.dart';
import 'package:app_flowy/plugins/grid/application/grid_bloc.dart';
import 'package:app_flowy/plugins/grid/application/grid_data_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test('create a text filter)', () async {
    final context = await gridTest.createTestGrid();
    final service = FilterFFIService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsEmpty,
        content: "");
    await gridResponseFuture();
    assert(context.fieldController.filterInfos.length == 1);
  });

  test('delete a text filter)', () async {
    final context = await gridTest.createTestGrid();
    final service = FilterFFIService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsEmpty,
        content: "");
    await gridResponseFuture();

    final filterInfo = context.fieldController.filterInfos.first;
    service.deleteFilter(
      fieldId: textField.id,
      filterId: filterInfo.filter.id,
      fieldType: textField.fieldType,
    );
    await gridResponseFuture();

    assert(context.fieldController.filterInfos.isEmpty);
  });

  test('filter rows with condition: text is empty', () async {
    final context = await gridTest.createTestGrid();
    final service = FilterFFIService(viewId: context.gridView.id);
    final gridController = GridController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      gridController: gridController,
    )..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsEmpty,
        content: "");
    await gridResponseFuture();

    assert(gridBloc.state.rowInfos.length == 3);
  });

  test('filter rows with condition: text is empty(After edit the row)',
      () async {
    final context = await gridTest.createTestGrid();
    final service = FilterFFIService(viewId: context.gridView.id);
    final gridController = GridController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      gridController: gridController,
    )..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsEmpty,
        content: "");
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
    final service = FilterFFIService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    await gridResponseFuture();
    service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsNotEmpty,
        content: "");
    await gridResponseFuture();
    assert(context.rowInfos.isEmpty);
  });

  test('filter rows with condition: checkbox uncheck', () async {
    final context = await gridTest.createTestGrid();
    final checkboxField = context.checkboxFieldContext();
    final service = FilterFFIService(viewId: context.gridView.id);
    final gridController = GridController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      gridController: gridController,
    )..add(const GridEvent.initial());

    await gridResponseFuture();
    service.insertCheckboxFilter(
      fieldId: checkboxField.id,
      condition: CheckboxFilterCondition.IsUnChecked,
    );
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.length == 3);
  });

  test('filter rows with condition: checkbox check', () async {
    final context = await gridTest.createTestGrid();
    final checkboxField = context.checkboxFieldContext();
    final service = FilterFFIService(viewId: context.gridView.id);
    final gridController = GridController(view: context.gridView);
    final gridBloc = GridBloc(
      view: context.gridView,
      gridController: gridController,
    )..add(const GridEvent.initial());

    await gridResponseFuture();
    service.insertCheckboxFilter(
      fieldId: checkboxField.id,
      condition: CheckboxFilterCondition.IsChecked,
    );
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.isEmpty);
  });
}
