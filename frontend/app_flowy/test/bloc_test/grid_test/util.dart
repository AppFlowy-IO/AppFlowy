import 'dart:collection';
import 'package:app_flowy/plugins/board/application/board_data_controller.dart';
import 'package:app_flowy/plugins/board/board.dart';
import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
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
  GridDataController? _gridDataController;
  BoardDataController? _boardDataController;

  AppFlowyGridTest({required this.unitTest});

  static Future<AppFlowyGridTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    return AppFlowyGridTest(unitTest: inner);
  }

  List<RowInfo> get rowInfos {
    if (_gridDataController != null) {
      return _gridDataController!.rowInfos;
    }

    if (_boardDataController != null) {
      return _boardDataController!.rowInfos;
    }

    throw Exception();
  }

  UnmodifiableMapView<String, GridBlockCache> get blocks {
    if (_gridDataController != null) {
      return _gridDataController!.blocks;
    }

    if (_boardDataController != null) {
      return _boardDataController!.blocks;
    }

    throw Exception();
  }

  List<GridFieldContext> get fieldContexts => fieldController.fieldContexts;

  GridFieldController get fieldController {
    if (_gridDataController != null) {
      return _gridDataController!.fieldController;
    }

    if (_boardDataController != null) {
      return _boardDataController!.fieldController;
    }

    throw Exception();
  }

  Future<void> createRow() async {
    if (_gridDataController != null) {
      return _gridDataController!.createRow();
    }

    throw Exception();
  }

  FieldEditorBloc createFieldEditor({
    GridFieldContext? fieldContext,
  }) {
    IFieldTypeOptionLoader loader;
    if (fieldContext == null) {
      loader = NewFieldTypeOptionLoader(gridId: gridView.id);
    } else {
      loader =
          FieldTypeOptionLoader(gridId: gridView.id, field: fieldContext.field);
    }

    final editorBloc = FieldEditorBloc(
      fieldName: fieldContext?.name ?? '',
      isGroupField: fieldContext?.isGroupField ?? false,
      loader: loader,
      gridId: gridView.id,
    );
    return editorBloc;
  }

  Future<IGridCellController> makeCellController(String fieldId) async {
    final builder = await makeCellControllerBuilder(fieldId);
    return builder.build();
  }

  Future<GridCellControllerBuilder> makeCellControllerBuilder(
    String fieldId,
  ) async {
    final RowInfo rowInfo = rowInfos.last;
    final blockCache = blocks[rowInfo.rowPB.blockId];
    final rowCache = blockCache?.rowCache;
    late GridFieldController fieldController;
    if (_gridDataController != null) {
      fieldController = _gridDataController!.fieldController;
    }

    if (_boardDataController != null) {
      fieldController = _boardDataController!.fieldController;
    }

    final rowDataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldController: fieldController,
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

  Future<FieldEditorBloc> createField(FieldType fieldType) async {
    final editorBloc = createFieldEditor()
      ..add(const FieldEditorEvent.initial());
    await gridResponseFuture();
    editorBloc.add(FieldEditorEvent.switchToField(fieldType));
    await gridResponseFuture();
    return Future(() => editorBloc);
  }

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
        _gridDataController = GridDataController(view: view);
        final result = await _gridDataController!.openGrid();
        result.fold((l) => null, (r) => throw Exception(r));
      },
      (error) {},
    );
  }

  Future<void> createTestBoard() async {
    final app = await unitTest.createTestApp();
    final builder = BoardPluginBuilder();
    final result = await AppService().createView(
      appId: app.id,
      name: "Test Board",
      dataFormatType: builder.dataFormatType,
      pluginType: builder.pluginType,
      layoutType: builder.layoutType!,
    );
    await result.fold(
      (view) async {
        _boardDataController = BoardDataController(view: view);
        final result = await _boardDataController!.openGrid();
        result.fold((l) => null, (r) => throw Exception(r));
        gridView = view;
      },
      (error) {},
    );
  }
}

/// Create a new Grid for cell test
class AppFlowyGridCellTest {
  final AppFlowyGridTest gridTest;
  AppFlowyGridCellTest({required this.gridTest});

  static Future<AppFlowyGridCellTest> ensureInitialized() async {
    final gridTest = await AppFlowyGridTest.ensureInitialized();
    return AppFlowyGridCellTest(gridTest: gridTest);
  }

  Future<void> createTestRow() async {
    await gridTest.createRow();
  }

  Future<void> createTestGrid() async {
    await gridTest.createTestGrid();
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

    final fieldContexts = _gridCellTest.gridTest.fieldContexts;
    final field =
        fieldContexts.firstWhere((element) => element.fieldType == fieldType);
    final cellController = await _gridCellTest.gridTest
        .makeCellController(field.id) as GridSelectOptionCellController;
    return cellController;
  }
}

Future<void> gridResponseFuture() {
  return Future.delayed(gridResponseDuration(milliseconds: 200));
}

Duration gridResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
