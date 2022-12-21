import 'package:app_flowy/plugins/board/application/board_data_controller.dart';
import 'package:app_flowy/plugins/board/board.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/application/row/row_bloc.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';

import '../../util.dart';
import '../grid_test/util.dart';

class AppFlowyBoardTest {
  final AppFlowyUnitTest unitTest;

  AppFlowyBoardTest({required this.unitTest});

  static Future<AppFlowyBoardTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    return AppFlowyBoardTest(unitTest: inner);
  }

  Future<BoardTestContext> createTestBoard() async {
    final app = await unitTest.createTestApp();
    final builder = BoardPluginBuilder();
    return AppService()
        .createView(
      appId: app.id,
      name: "Test Board",
      dataFormatType: builder.dataFormatType,
      pluginType: builder.pluginType,
      layoutType: builder.layoutType!,
    )
        .then((result) {
      return result.fold(
        (view) async {
          final context =
              BoardTestContext(view, BoardDataController(view: view));
          final result = await context._boardDataController.openGrid();
          result.fold((l) => null, (r) => throw Exception(r));
          return context;
        },
        (error) {
          throw Exception();
        },
      );
    });
  }
}

Future<void> boardResponseFuture() {
  return Future.delayed(boardResponseDuration(milliseconds: 200));
}

Duration boardResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}

class BoardTestContext {
  final ViewPB gridView;
  final BoardDataController _boardDataController;

  BoardTestContext(this.gridView, this._boardDataController);

  List<RowInfo> get rowInfos {
    return _boardDataController.rowInfos;
  }

  List<FieldInfo> get fieldContexts => fieldController.fieldInfos;

  GridFieldController get fieldController {
    return _boardDataController.fieldController;
  }

  FieldEditorBloc createFieldEditor({
    FieldInfo? fieldInfo,
  }) {
    IFieldTypeOptionLoader loader;
    if (fieldInfo == null) {
      loader = NewFieldTypeOptionLoader(gridId: gridView.id);
    } else {
      loader =
          FieldTypeOptionLoader(gridId: gridView.id, field: fieldInfo.field);
    }

    final editorBloc = FieldEditorBloc(
      fieldName: fieldInfo?.name ?? '',
      isGroupField: fieldInfo?.isGroupField ?? false,
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
    final rowCache = _boardDataController.rowCache;
    final fieldController = _boardDataController.fieldController;

    final rowDataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldController: fieldController,
      rowCache: rowCache,
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

  FieldInfo singleSelectFieldContext() {
    final fieldInfo = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.SingleSelect);
    return fieldInfo;
  }

  GridFieldCellContext singleSelectFieldCellContext() {
    final field = singleSelectFieldContext().field;
    return GridFieldCellContext(gridId: gridView.id, field: field);
  }

  FieldInfo textFieldContext() {
    final fieldInfo = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.RichText);
    return fieldInfo;
  }

  FieldInfo checkboxFieldContext() {
    final fieldInfo = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.Checkbox);
    return fieldInfo;
  }
}
