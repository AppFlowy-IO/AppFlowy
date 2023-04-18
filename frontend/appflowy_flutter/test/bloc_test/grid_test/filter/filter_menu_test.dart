import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/filter/filter_menu_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pb.dart';
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
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    )..add(const GridFilterMenuEvent.initial());
    await gridResponseFuture();
    assert(menuBloc.state.creatableFields.length == 3);

    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();
    assert(menuBloc.state.creatableFields.length == 2);
  });

  test('test filter menu after update existing text filter)', () async {
    final context = await gridTest.createTestGrid();
    final menuBloc = GridFilterMenuBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    )..add(const GridFilterMenuEvent.initial());
    await gridResponseFuture();

    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();

    // Create filter
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();

    final textFilter = context.fieldController.filterInfos.first;
    // Update the existing filter
    await service.insertTextFilter(
      fieldId: textField.id,
      filterId: textFilter.filter.id,
      condition: TextFilterConditionPB.Is,
      content: "ABC",
    );
    await gridResponseFuture();
    assert(
      menuBloc.state.filters.first.textFilter()!.condition ==
          TextFilterConditionPB.Is,
    );
    assert(menuBloc.state.filters.first.textFilter()!.content == "ABC");
  });
}
