import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';
import 'filter_util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test('filter rows by text is empty condition)', () async {
    final context = await createTestFilterGrid(gridTest);

    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    // create a new filter
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();
    assert(
      context.fieldController.filters.length == 1,
      "expect 1 but receive ${context.fieldController.filters.length}",
    );
    assert(
      context.rowInfos.length == 1,
      "expect 1 but receive ${context.rowInfos.length}",
    );

    // delete the filter
    final textFilter = context.fieldController.filters.first;
    await service.deleteFilter(
      filterId: textFilter.filterId,
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 3);
  });

  test('filter rows by text is not empty condition)', () async {
    final context = await createTestFilterGrid(gridTest);

    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    // create a new filter
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsNotEmpty,
      content: "",
    );
    await gridResponseFuture();
    assert(
      context.rowInfos.length == 2,
      "expect 2 but receive ${context.rowInfos.length}",
    );

    // delete the filter
    final textFilter = context.fieldController.filters.first;
    await service.deleteFilter(
      filterId: textFilter.filterId,
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 3);
  });

  test('filter rows by text is empty or is not empty condition)', () async {
    final context = await createTestFilterGrid(gridTest);

    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    // create a new filter
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIsEmpty,
      content: "",
    );
    await gridResponseFuture();
    assert(
      context.fieldController.filters.length == 1,
      "expect 1 but receive ${context.fieldController.filters.length}",
    );
    assert(
      context.rowInfos.length == 1,
      "expect 1 but receive ${context.rowInfos.length}",
    );

    // Update the existing filter
    final textFilter = context.fieldController.filters.first;
    await service.insertTextFilter(
      fieldId: textField.id,
      filterId: textFilter.filterId,
      condition: TextFilterConditionPB.TextIsNotEmpty,
      content: "",
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 2);

    // delete the filter
    await service.deleteFilter(
      filterId: textFilter.filterId,
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 3);
  });

  test('filter rows by text is condition)', () async {
    final context = await createTestFilterGrid(gridTest);

    final service = FilterBackendService(viewId: context.gridView.id);
    final textField = context.textFieldContext();
    // create a new filter
    await service.insertTextFilter(
      fieldId: textField.id,
      condition: TextFilterConditionPB.TextIs,
      content: "A",
    );
    await gridResponseFuture();
    assert(
      context.rowInfos.length == 1,
      "expect 1 but receive ${context.rowInfos.length}",
    );

    // Update the existing filter's content from 'A' to 'B'
    final textFilter = context.fieldController.filters.first;
    await service.insertTextFilter(
      fieldId: textField.id,
      filterId: textFilter.filterId,
      condition: TextFilterConditionPB.TextIs,
      content: "B",
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 1);

    // Update the existing filter's content from 'B' to 'b'
    await service.insertTextFilter(
      fieldId: textField.id,
      filterId: textFilter.filterId,
      condition: TextFilterConditionPB.TextIs,
      content: "b",
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 1);

    // Update the existing filter with content 'C'
    await service.insertTextFilter(
      fieldId: textField.id,
      filterId: textFilter.filterId,
      condition: TextFilterConditionPB.TextIs,
      content: "C",
    );
    await gridResponseFuture();
    assert(context.rowInfos.isEmpty);

    // delete the filter
    await service.deleteFilter(
      filterId: textFilter.filterId,
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 3);
  });
}
