import 'package:appflowy/plugins/database_view/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/board/board.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_bloc.dart';
import 'package:appflowy/workspace/application/app/app_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';

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
    return AppBackendService()
        .createView(
      appId: app.id,
      name: "Test Board",
      layoutType: builder.layoutType!,
    )
        .then((result) {
      return result.fold(
        (view) async {
          final context = BoardTestContext(
            view,
            DatabaseController(
              view: view,
              layoutType: LayoutTypePB.Board,
            ),
          );
          final result = await context._boardDataController.open();
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
  final DatabaseController _boardDataController;

  BoardTestContext(this.gridView, this._boardDataController);

  List<RowInfo> get rowInfos {
    return _boardDataController.rowCache.rowInfos;
  }

  List<FieldInfo> get fieldContexts => fieldController.fieldInfos;

  FieldController get fieldController {
    return _boardDataController.fieldController;
  }

  FieldEditorBloc createFieldEditor({
    FieldInfo? fieldInfo,
  }) {
    IFieldTypeOptionLoader loader;
    if (fieldInfo == null) {
      loader = NewFieldTypeOptionLoader(viewId: gridView.id);
    } else {
      loader =
          FieldTypeOptionLoader(viewId: gridView.id, field: fieldInfo.field);
    }

    final editorBloc = FieldEditorBloc(
      fieldName: fieldInfo?.name ?? '',
      isGroupField: fieldInfo?.isGroupField ?? false,
      loader: loader,
      viewId: gridView.id,
    );
    return editorBloc;
  }

  Future<CellController> makeCellController(String fieldId) async {
    final builder = await makeCellControllerBuilder(fieldId);
    return builder.build();
  }

  Future<CellControllerBuilder> makeCellControllerBuilder(
    String fieldId,
  ) async {
    final RowInfo rowInfo = rowInfos.last;
    final rowCache = _boardDataController.rowCache;

    final rowDataController = RowController(
      viewId: rowInfo.viewId,
      rowId: rowInfo.rowPB.id,
      rowCache: rowCache,
    );

    final rowBloc = RowBloc(
      rowInfo: rowInfo,
      dataController: rowDataController,
    )..add(const RowEvent.initial());
    await gridResponseFuture();

    return CellControllerBuilder(
      cellId: rowBloc.state.cellByFieldId[fieldId]!,
      cellCache: rowCache.cellCache,
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

  FieldCellContext singleSelectFieldCellContext() {
    final field = singleSelectFieldContext().field;
    return FieldCellContext(viewId: gridView.id, field: field);
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
