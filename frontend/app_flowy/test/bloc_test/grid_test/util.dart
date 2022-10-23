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
    return AppFlowyGridTest(inner);
  }

  Future<void> createTestGrid() async {
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
  final AppFlowyGridCellTest _gridCellTest;

  AppFlowyGridSelectOptionCellTest(AppFlowyGridCellTest cellTest)
      : _gridCellTest = cellTest;

  static Future<AppFlowyGridSelectOptionCellTest> ensureInitialized() async {
    final gridTest = await AppFlowyGridCellTest.ensureInitialized();
    return AppFlowyGridSelectOptionCellTest(gridTest);
  }

  Future<void> createTestGrid() async {
    await _gridCellTest.createTestGrid();
  }

  Future<void> createTestRow() async {
    await _gridCellTest.createTestRow();
  }

  Future<GridSelectOptionCellController> makeCellController(
      FieldType fieldType) async {
    assert(fieldType == FieldType.SingleSelect ||
        fieldType == FieldType.MultiSelect);

    final fieldContexts =
        _gridCellTest._dataController.fieldController.fieldContexts;
    final field =
        fieldContexts.firstWhere((element) => element.fieldType == fieldType);
    final builder = await _gridCellTest.cellControllerBuilder(field.id);
    final cellController = builder.build() as GridSelectOptionCellController;
    return cellController;
  }
}

/// Create a new Grid for cell test
class AppFlowyGridCellTest {
  final AppFlowyGridTest _gridTest;
  late GridDataController _dataController;
  AppFlowyGridCellTest(AppFlowyGridTest gridTest) : _gridTest = gridTest;

  static Future<AppFlowyGridCellTest> ensureInitialized() async {
    final gridTest = await AppFlowyGridTest.ensureInitialized();
    return AppFlowyGridCellTest(gridTest);
  }

  Future<void> createTestRow() async {
    await _dataController.createRow();
  }

  Future<void> createTestGrid() async {
    await _gridTest.createTestGrid();
    _dataController = GridDataController(view: _gridTest.gridView);
    final result = await _dataController.loadData();
    result.fold((l) => null, (r) => throw Exception(r));
  }

  Future<GridCellControllerBuilder> cellControllerBuilder(
    String fieldId,
  ) async {
    final RowInfo rowInfo = _dataController.rowInfos.last;
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
    await gridResponseFuture();

    return GridCellControllerBuilder(
      cellId: rowBloc.state.gridCellMap[fieldId]!,
      cellCache: rowCache.cellCache,
      delegate: rowDataController,
    );
  }
}

Future<void> gridResponseFuture() {
  return Future.delayed(gridResponseDuration(milliseconds: 200));
}

Duration gridResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
