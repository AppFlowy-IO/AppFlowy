import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test('create a text filter)', () async {
    final context = await gridTest.createTestGrid();
    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();

    assert(context.fieldController.filterInfos.length == 1);
  });

  test('delete a text filter)', () async {
    final context = await gridTest.createTestGrid();
    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();

    final filterInfo = context.fieldController.filterInfos.first;
    await service.deleteFilter(
      fieldId: textField.id,
      filterId: filterInfo.filter.id,
    );
    await gridResponseFuture();

    expect(context.fieldController.filterInfos.length, 0);
  });

  test('filter rows with condition: text is empty', () async {
    final context = await gridTest.createTestGrid();
    final service = FilterBackendService(viewId: context.gridView.id);
    final gridController = DatabaseController(
      view: context.gridView,
    );
    final gridBloc = GridBloc(
      view: context.gridView,
      databaseController: gridController,
    )..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();

    expect(gridBloc.state.rowInfos.length, 3);
  });

  test('filter rows with condition: text is empty(After edit the row)',
      () async {
    final context = await gridTest.createTestGrid();
    final service = FilterBackendService(viewId: context.gridView.id);
    final gridController = DatabaseController(
      view: context.gridView,
    );
    final gridBloc = GridBloc(
      view: context.gridView,
      databaseController: gridController,
    )..add(const GridEvent.initial());
    await gridResponseFuture();

    final textField = context.textFieldContext();
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();

    final controller = context.makeTextCellController(0);
    await controller.saveCellData("edit text cell content");
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.length == 2);

    await controller.saveCellData("");
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.length == 3);
  });

  test('filter rows with condition: text is not empty', () async {
    final context = await gridTest.createTestGrid();
    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    await gridResponseFuture();
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsNotEmpty,
      content: "",
    );
    await gridResponseFuture();
    assert(context.rowInfos.isEmpty);
  });

  test('filter rows with condition: checkbox uncheck', () async {
    final context = await gridTest.createTestGrid();
    final checkboxField = context.checkboxFieldContext();
    final service = FilterBackendService(viewId: context.gridView.id);
    final gridController = DatabaseController(
      view: context.gridView,
    );
    final gridBloc = GridBloc(
      view: context.gridView,
      databaseController: gridController,
    )..add(const GridEvent.initial());

    await gridResponseFuture();
    await service.insertCheckboxFilter(
      fieldId: checkboxField.id,
      condition: CheckboxFilterConditionPB.IsUnChecked,
    );
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.length == 3);
  });

  test('filter rows with condition: checkbox check', () async {
    final context = await gridTest.createTestGrid();
    final checkboxField = context.checkboxFieldContext();
    final service = FilterBackendService(viewId: context.gridView.id);
    final gridController = DatabaseController(
      view: context.gridView,
    );
    final gridBloc = GridBloc(
      view: context.gridView,
      databaseController: gridController,
    )..add(const GridEvent.initial());

    await gridResponseFuture();
    await service.insertCheckboxFilter(
      fieldId: checkboxField.id,
      condition: CheckboxFilterConditionPB.IsChecked,
    );
    await gridResponseFuture();
    assert(gridBloc.state.rowInfos.isEmpty);
  });
}
