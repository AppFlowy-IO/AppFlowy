import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
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
    final menuBloc = FilterEditorBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    );
    await gridResponseFuture();
    assert(menuBloc.state.fields.length == 3);

    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();
    assert(menuBloc.state.fields.length == 3);
  });

  test('test filter menu after update existing text filter)', () async {
    final context = await gridTest.createTestGrid();
    final menuBloc = FilterEditorBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    );
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
      condition: TextFilterConditionPB.TextIs,
      content: "ABC",
    );
    await gridResponseFuture();
    assert(
      menuBloc.state.filters.first.textFilter()!.condition ==
          TextFilterConditionPB.TextIs,
    );
    assert(menuBloc.state.filters.first.textFilter()!.content == "ABC");
  });
}
