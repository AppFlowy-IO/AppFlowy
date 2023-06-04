import 'package:appflowy/plugins/database_view/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/grid.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:dartz/dartz.dart';

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

  Future<Either<RowPB, FlowyError>> createRow() async {
    return gridController.createRow();
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
      rowId: rowInfo.rowPB.id,
      viewId: rowInfo.viewId,
      rowCache: rowCache,
    );

    final rowBloc = RowBloc(
      rowInfo: rowInfo,
      dataController: rowDataController,
    )..add(const RowEvent.initial());
    await gridResponseFuture();

    return CellControllerBuilder(
      cellContext: rowBloc.state.cellByFieldId[fieldId]!,
      cellCache: rowCache.cellCache,
    );
  }

  Future<FieldEditorBloc> createField(FieldType fieldType) async {
    final editorBloc = await createFieldEditor(viewId: gridView.id)
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

  FieldContext singleSelectFieldCellContext() {
    final field = singleSelectFieldContext().field;
    return FieldContext(viewId: gridView.id, field: field);
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
  required String viewId,
}) async {
  final result = await TypeOptionBackendService.createFieldTypeOption(
    viewId: viewId,
  );
  return result.fold(
    (data) {
      final loader = FieldTypeOptionLoader(
        viewId: viewId,
        field: data.field_2,
      );
      return FieldEditorBloc(
        isGroupField: FieldInfo(field: data.field_2).isGroupField,
        loader: loader,
        field: data.field_2,
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
    final app = await unitTest.createTestApp();
    final builder = GridPluginBuilder();
    final context = await ViewBackendService.createView(
      parentViewId: app.id,
      name: "Test Grid",
      layoutType: builder.layoutType!,
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
    await context.createRow();
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
