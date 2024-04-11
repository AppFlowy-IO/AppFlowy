import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

import '../../util.dart';

class GridTestContext {
  GridTestContext(this.gridView, this.gridController);

  final ViewPB gridView;
  final DatabaseController gridController;

  List<RowInfo> get rowInfos {
    return gridController.rowCache.rowInfos;
  }

  List<FieldInfo> get fieldInfos => fieldController.fieldInfos;

  FieldController get fieldController {
    return gridController.fieldController;
  }

  Future<FieldEditorBloc> createField(FieldType fieldType) async {
    final editorBloc =
        await createFieldEditor(databaseController: gridController);
    await gridResponseFuture();
    editorBloc.add(FieldEditorEvent.switchFieldType(fieldType));
    await gridResponseFuture();
    return Future(() => editorBloc);
  }

  FieldInfo singleSelectFieldContext() {
    final fieldInfo = fieldInfos
        .firstWhere((element) => element.fieldType == FieldType.SingleSelect);
    return fieldInfo;
  }

  FieldInfo textFieldContext() {
    final fieldInfo = fieldInfos
        .firstWhere((element) => element.fieldType == FieldType.RichText);
    return fieldInfo;
  }

  FieldInfo checkboxFieldContext() {
    final fieldInfo = fieldInfos
        .firstWhere((element) => element.fieldType == FieldType.Checkbox);
    return fieldInfo;
  }

  SelectOptionCellController makeSelectOptionCellController(
    FieldType fieldType,
    int rowIndex,
  ) {
    assert(
      fieldType == FieldType.SingleSelect || fieldType == FieldType.MultiSelect,
    );
    final field =
        fieldInfos.firstWhere((fieldInfo) => fieldInfo.fieldType == fieldType);
    return makeCellController(
      gridController,
      CellContext(fieldId: field.id, rowId: rowInfos[rowIndex].rowId),
    ).as();
  }

  TextCellController makeTextCellController(int rowIndex) {
    final field = fieldInfos
        .firstWhere((element) => element.fieldType == FieldType.RichText);
    return makeCellController(
      gridController,
      CellContext(fieldId: field.id, rowId: rowInfos[rowIndex].rowId),
    ).as();
  }

  CheckboxCellController makeCheckboxCellController(int rowIndex) {
    final field = fieldInfos
        .firstWhere((element) => element.fieldType == FieldType.Checkbox);
    return makeCellController(
      gridController,
      CellContext(fieldId: field.id, rowId: rowInfos[rowIndex].rowId),
    ).as();
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
  AppFlowyGridTest({required this.unitTest});

  final AppFlowyUnitTest unitTest;

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
  AppFlowyGridCellTest({required this.gridTest});

  late GridTestContext context;
  final AppFlowyGridTest gridTest;

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

  SelectOptionCellController makeSelectOptionCellController(
    FieldType fieldType,
    int rowIndex,
  ) =>
      context.makeSelectOptionCellController(fieldType, rowIndex);
}

Future<void> gridResponseFuture({int milliseconds = 200}) {
  return Future.delayed(gridResponseDuration(milliseconds: milliseconds));
}

Duration gridResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
