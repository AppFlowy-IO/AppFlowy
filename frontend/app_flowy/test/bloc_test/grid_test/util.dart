import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_data_controller.dart';
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
  final AppFlowyUnitTest unitTest;
  late ViewPB gridView;
  late GridDataController _dataController;

  AppFlowyGridTest({required this.unitTest});

  static Future<AppFlowyGridTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    return AppFlowyGridTest(unitTest: inner);
  }

  List<RowInfo> get rowInfos => _dataController.rowInfos;

  UnmodifiableMapView<String, GridBlockCache> get blocks =>
      _dataController.blocks;

  List<GridFieldContext> get fieldContexts =>
      _dataController.fieldController.fieldContexts;

  GridFieldController get fieldController => _dataController.fieldController;

  Future<void> createRow() async {
    await _dataController.createRow();
  }

  // Future<TypeOptionContext> createField(FieldType fieldType) {
  //   final controller = TypeOptionDataController(
  //     gridId: gridView.id,
  //     loader: NewFieldTypeOptionLoader(gridId: gridView.id),
  //   );

  //   switch (fieldType) {

  //     case FieldType.Checkbox:
  //       // TODO: Handle this case.

  //       break;
  //     case FieldType.DateTime:
  //       // TODO: Handle this case.
  //       break;
  //     case FieldType.MultiSelect:
  //       // TODO: Handle this case.
  //       break;
  //     case FieldType.Number:
  //       return NumberTypeOptionContext()
  //       break;
  //     case FieldType.RichText:
  //       // TODO: Handle this case.
  //       break;
  //     case FieldType.SingleSelect:
  //       // TODO: Handle this case.
  //       break;
  //     case FieldType.URL:
  //       // TODO: Handle this case.
  //       break;
  //   }
  // }

  GridFieldContext singleSelectFieldContext() {
    final fieldContext = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.SingleSelect);
    return fieldContext;
  }

  GridFieldCellContext singleSelectFieldCellContext() {
    final field = singleSelectFieldContext().field;
    return GridFieldCellContext(gridId: gridView.id, field: field);
  }

  Future<void> createTestGrid() async {
    final app = await unitTest.createTestApp();
    final builder = GridPluginBuilder();
    final result = await AppService().createView(
      appId: app.id,
      name: "Test Grid",
      dataFormatType: builder.dataFormatType,
      pluginType: builder.pluginType,
      layoutType: builder.layoutType!,
    );
    await result.fold(
      (view) async {
        gridView = view;
        _dataController = GridDataController(view: view);
        final result = await _dataController.openGrid();
        result.fold((l) => null, (r) => throw Exception(r));
      },
      (error) {},
    );
  }
}

/// Create a new Grid for cell test
class AppFlowyGridCellTest {
  final AppFlowyGridTest _gridTest;
  AppFlowyGridCellTest(AppFlowyGridTest gridTest) : _gridTest = gridTest;

  static Future<AppFlowyGridCellTest> ensureInitialized() async {
    final gridTest = await AppFlowyGridTest.ensureInitialized();
    return AppFlowyGridCellTest(gridTest);
  }

  Future<void> createTestRow() async {
    await _gridTest.createRow();
  }

  Future<void> createTestGrid() async {
    await _gridTest.createTestGrid();
  }

  Future<GridCellControllerBuilder> cellControllerBuilder(
    String fieldId,
  ) async {
    final RowInfo rowInfo = _gridTest.rowInfos.last;
    final blockCache = _gridTest.blocks[rowInfo.rowPB.blockId];
    final rowCache = blockCache?.rowCache;

    final rowDataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldController: _gridTest._dataController.fieldController,
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

    final fieldContexts = _gridCellTest._gridTest.fieldContexts;
    final field =
        fieldContexts.firstWhere((element) => element.fieldType == fieldType);
    final builder = await _gridCellTest.cellControllerBuilder(field.id);
    final cellController = builder.build() as GridSelectOptionCellController;
    return cellController;
  }
}

Future<void> gridResponseFuture() {
  return Future.delayed(gridResponseDuration(milliseconds: 200));
}

Duration gridResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
