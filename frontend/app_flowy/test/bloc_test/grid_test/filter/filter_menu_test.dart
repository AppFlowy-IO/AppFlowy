import 'package:app_flowy/plugins/grid/application/filter/filter_menu_bloc.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test('test filter menu after create a text filter)', () async {
    final context = await gridTest.createTestGrid();
    final menuBloc = GridFilterMenuBloc(
        viewId: context.gridView.id, fieldController: context.fieldController)
      ..add(const GridFilterMenuEvent.initial());
    await gridResponseFuture();
    assert(menuBloc.state.creatableFields.length == 2);

    final service = FilterFFIService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    await service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsEmpty,
        content: "");
    await gridResponseFuture();
    assert(menuBloc.state.creatableFields.length == 1);
  });

  test('test filter menu after update existing text filter)', () async {
    final context = await gridTest.createTestGrid();
    final menuBloc = GridFilterMenuBloc(
        viewId: context.gridView.id, fieldController: context.fieldController)
      ..add(const GridFilterMenuEvent.initial());
    await gridResponseFuture();

    final service = FilterFFIService(viewId: context.gridView.id);
    final textField = context.textFieldContext();

    // Create filter
    await service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsEmpty,
        content: "");
    await gridResponseFuture();

    final textFilter = context.fieldController.filterInfos.first;
    // Update the existing filter
    await service.insertTextFilter(
        fieldId: textField.id,
        filterId: textFilter.filter.id,
        condition: TextFilterCondition.Is,
        content: "ABC");
    await gridResponseFuture();
    assert(menuBloc.state.filters.first.textFilter()!.condition ==
        TextFilterCondition.Is);
    assert(menuBloc.state.filters.first.textFilter()!.content == "ABC");
  });
}
