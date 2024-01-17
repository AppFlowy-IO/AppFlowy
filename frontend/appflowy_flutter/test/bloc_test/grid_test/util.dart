import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/field_service.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

import '../../util.dart';

class GridTestContext {
  final ViewPB gridView;
  final DatabaseController gridController;

  GridTestContext(this.gridView, this.gridController);

  List<RowInfo> get rowInfos {
    return gridController.rowCache.rowInfos;
  }

  List<FieldInfo> get fieldContexts => fieldController.fieldInfos;

  FieldController get fieldController {
    return gridController.fieldController;
  }

  Future<CellController> makeCellController(
    String fieldId,
    int rowIndex,
  ) async {
    final builder = await makeCellControllerBuilder(fieldId, rowIndex);
    return builder.build();
  }

  Future<CellControllerBuilder> makeCellControllerBuilder(
    String fieldId,
    int rowIndex,
  ) async {
    final RowInfo rowInfo = rowInfos[rowIndex];
    final rowCache = gridController.rowCache;

    final rowDataController = RowController(
      rowMeta: rowInfo.rowMeta,
      viewId: rowInfo.viewId,
      rowCache: rowCache,
    );

    final rowBloc = RowBloc(
      viewId: rowInfo.viewId,
      dataController: rowDataController,
      rowId: rowInfo.rowMeta.id,
    )..add(const RowEvent.initial());
    await gridResponseFuture();

    return CellControllerBuilder(
      cellContext: rowBloc.state.cellByFieldId[fieldId]!,
      cellCache: rowCache.cellCache,
    );
  }

  Future<FieldEditorBloc> createField(FieldType fieldType) async {
    final editorBloc =
        await createFieldEditor(databaseController: gridController)
          ..add(const FieldEditorEvent.initial());
    await gridResponseFuture();
    editorBloc.add(FieldEditorEvent.switchFieldType(fieldType));
    await gridResponseFuture();
    return Future(() => editorBloc);
  }

  FieldInfo singleSelectFieldContext() {
    final fieldInfo = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.SingleSelect);
    return fieldInfo;
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

  Future<SelectOptionCellController> makeSelectOptionCellController(
    FieldType fieldType,
    int rowIndex,
  ) async {
    assert(
      fieldType == FieldType.SingleSelect || fieldType == FieldType.MultiSelect,
    );

    final field =
        fieldContexts.firstWhere((element) => element.fieldType == fieldType);
    final cellController = await makeCellController(field.id, rowIndex)
        as SelectOptionCellController;
    return cellController;
  }

  Future<TextCellController> makeTextCellController(int rowIndex) async {
    final field = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.RichText);
    final cellController =
        await makeCellController(field.id, rowIndex) as TextCellController;
    return cellController;
  }

  Future<TextCellController> makeCheckboxCellController(int rowIndex) async {
    final field = fieldContexts
        .firstWhere((element) => element.fieldType == FieldType.Checkbox);
    final cellController =
        await makeCellController(field.id, rowIndex) as TextCellController;
    return cellController;
  }
}

Future<FieldEditorBloc> createFieldEditor({
  required DatabaseController databaseController,
}) async {
  final result = await FieldBackendService.createField(
    viewId: databaseController.viewId,
  );
  await gridResponseFuture();
  return result.fold(
    (field) {
      return FieldEditorBloc(
        viewId: databaseController.viewId,
        fieldController: databaseController.fieldController,
        field: field,
      );
    },
    (err) => throw Exception(err),
  );
}

/// Create a empty Grid for test
class AppFlowyGridTest {
  final AppFlowyUnitTest unitTest;

  AppFlowyGridTest({required this.unitTest});

  static Future<AppFlowyGridTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    return AppFlowyGridTest(unitTest: inner);
  }

  Future<GridTestContext> createTestGrid() async {
    final app = await unitTest.createWorkspace();
    final context = await ViewBackendService.createView(
      parentViewId: app.id,
      name: "Test Grid",
      layoutType: ViewLayoutPB.Grid,
      openAfterCreate: true,
    ).then((result) {
      return result.fold(
        (view) async {
          final context = GridTestContext(
            view,
            DatabaseController(view: view),
          );
          final result = await context.gridController.open();
          result.fold((l) => null, (r) => throw Exception(r));
          return context;
        },
        (error) {
          throw Exception();
        },
      );
    });

    return context;
  }
}

/// Create a new Grid for cell test
class AppFlowyGridCellTest {
  late GridTestContext context;
  final AppFlowyGridTest gridTest;
  AppFlowyGridCellTest({required this.gridTest});

  static Future<AppFlowyGridCellTest> ensureInitialized() async {
    final gridTest = await AppFlowyGridTest.ensureInitialized();
    return AppFlowyGridCellTest(gridTest: gridTest);
  }

  Future<void> createTestGrid() async {
    context = await gridTest.createTestGrid();
  }

  Future<void> createTestRow() async {
    await RowBackendService.createRow(viewId: context.gridView.id);
  }

  Future<SelectOptionCellController> makeSelectOptionCellController(
    FieldType fieldType,
    int rowIndex,
  ) async {
    return await context.makeSelectOptionCellController(fieldType, rowIndex);
  }
}

Future<void> gridResponseFuture({int milliseconds = 200}) {
  return Future.delayed(gridResponseDuration(milliseconds: milliseconds));
}

Duration gridResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
