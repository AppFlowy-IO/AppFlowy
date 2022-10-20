import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/grid_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_bloc.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/plugins/grid/grid.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';

import '../../util.dart';

/// Create a empty Grid for test
class AppFlowyGridTest {
  // ignore: unused_field
  final AppFlowyUnitTest _inner;
  late ViewPB gridView;
  AppFlowyGridTest(AppFlowyUnitTest unitTest) : _inner = unitTest;

  static Future<AppFlowyGridTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    final test = AppFlowyGridTest(inner);
    await test._createTestGrid();
    return test;
  }

  Future<void> _createTestGrid() async {
    final app = await _inner.createTestApp();
    final builder = GridPluginBuilder();
    final result = await AppService().createView(
      appId: app.id,
      name: "Test Grid",
      dataFormatType: builder.dataFormatType,
      pluginType: builder.pluginType,
      layoutType: builder.layoutType!,
    );
    result.fold(
      (view) => gridView = view,
      (error) {},
    );
  }
}

class AppFlowyGridSelectOptionCellTest {
  final AppFlowyGridCellTest _cellTest;

  AppFlowyGridSelectOptionCellTest(AppFlowyGridCellTest cellTest)
      : _cellTest = cellTest;

  static Future<AppFlowyGridSelectOptionCellTest> ensureInitialized() async {
    final cellTest = await AppFlowyGridCellTest.ensureInitialized();
    final test = AppFlowyGridSelectOptionCellTest(cellTest);
    return test;
  }

  /// For the moment, just edit the first row of the grid.
  Future<GridSelectOptionCellController> makeCellController(
      FieldType fieldType) async {
    assert(fieldType == FieldType.SingleSelect ||
        fieldType == FieldType.MultiSelect);

    final fieldContexts =
        _cellTest._dataController.fieldController.fieldContexts;
    final field =
        fieldContexts.firstWhere((element) => element.fieldType == fieldType);
    final builder = await _cellTest.cellControllerBuilder(0, field.id);
    final cellController = builder.build() as GridSelectOptionCellController;
    return cellController;
  }
}

class AppFlowyGridCellTest {
  // ignore: unused_field
  final AppFlowyGridTest _gridTest;
  final GridDataController _dataController;
  AppFlowyGridCellTest(AppFlowyGridTest gridTest)
      : _gridTest = gridTest,
        _dataController = GridDataController(view: gridTest.gridView);

  static Future<AppFlowyGridCellTest> ensureInitialized() async {
    final gridTest = await AppFlowyGridTest.ensureInitialized();
    final test = AppFlowyGridCellTest(gridTest);
    await test._loadGridData();
    return test;
  }

  Future<void> _loadGridData() async {
    final result = await _dataController.loadData();
    result.fold((l) => null, (r) => throw Exception(r));
  }

  Future<GridCellControllerBuilder> cellControllerBuilder(
      int rowIndex, String fieldId) async {
    final RowInfo rowInfo = _dataController.rowInfos[rowIndex];
    final blockCache = _dataController.blocks[rowInfo.rowPB.blockId];
    final rowCache = blockCache?.rowCache;

    final rowDataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldController: _dataController.fieldController,
      rowCache: rowCache!,
    );

    final rowBloc = RowBloc(
      rowInfo: rowInfo,
      dataController: rowDataController,
    )..add(const RowEvent.initial());
    await gridResponseFuture(milliseconds: 300);

    return GridCellControllerBuilder(
      cellId: rowBloc.state.gridCellMap[fieldId]!,
      cellCache: rowCache.cellCache,
      delegate: rowDataController,
    );
  }
}

Future<void> gridResponseFuture({int milliseconds = 200}) {
  return Future.delayed(gridResponseDuration(milliseconds: milliseconds));
}

Duration gridResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
