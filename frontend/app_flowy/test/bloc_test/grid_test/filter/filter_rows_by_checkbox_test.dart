import 'package:app_flowy/plugins/grid/application/filter/filter_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';
import 'filter_util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test('filter rows by checkbox is check condition)', () async {
    final context = await createTestFilterGrid(gridTest);
    final service = FilterFFIService(viewId: context.gridView.id);

    final controller = await context.makeCheckboxCellController(0);
    controller.saveCellData("Yes");
    await gridResponseFuture();

    // create a new filter
    final checkboxField = context.checkboxFieldContext();
    await service.insertCheckboxFilter(
      fieldId: checkboxField.id,
      condition: CheckboxFilterCondition.IsChecked,
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 1,
        "expect 1 but receive ${context.rowInfos.length}");
  });

  test('filter rows by checkbox is uncheck condition)', () async {
    final context = await createTestFilterGrid(gridTest);
    final service = FilterFFIService(viewId: context.gridView.id);

    final controller = await context.makeCheckboxCellController(0);
    controller.saveCellData("Yes");
    await gridResponseFuture();

    // create a new filter
    final checkboxField = context.checkboxFieldContext();
    await service.insertCheckboxFilter(
      fieldId: checkboxField.id,
      condition: CheckboxFilterCondition.IsUnChecked,
    );
    await gridResponseFuture();
    assert(context.rowInfos.length == 2,
        "expect 2 but receive ${context.rowInfos.length}");
  });
}
