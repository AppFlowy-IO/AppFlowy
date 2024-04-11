import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/board/board.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

import '../../util.dart';
import '../grid_test/util.dart';

class AppFlowyBoardTest {
  AppFlowyBoardTest({required this.unitTest});

  final AppFlowyUnitTest unitTest;

  static Future<AppFlowyBoardTest> ensureInitialized() async {
    final inner = await AppFlowyUnitTest.ensureInitialized();
    return AppFlowyBoardTest(unitTest: inner);
  }

  Future<BoardTestContext> createTestBoard() async {
    final app = await unitTest.createWorkspace();
    final builder = BoardPluginBuilder();
    return ViewBackendService.createView(
      parentViewId: app.id,
      name: "Test Board",
      layoutType: builder.layoutType!,
      openAfterCreate: true,
    ).then((result) {
      return result.fold(
        (view) async {
          final context = BoardTestContext(
            view,
            DatabaseController(view: view),
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
  return Future.delayed(boardResponseDuration());
}

Duration boardResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}

class BoardTestContext {
  BoardTestContext(this.gridView, this._boardDataController);

  final ViewPB gridView;
  final DatabaseController _boardDataController;

  List<RowInfo> get rowInfos {
    return _boardDataController.rowCache.rowInfos;
  }

  List<FieldInfo> get fieldContexts => fieldController.fieldInfos;

  FieldController get fieldController {
    return _boardDataController.fieldController;
  }

  DatabaseController get databaseController => _boardDataController;

  FieldEditorBloc makeFieldEditor({
    required FieldInfo fieldInfo,
  }) {
    final editorBloc = FieldEditorBloc(
      viewId: databaseController.viewId,
      fieldController: fieldController,
      field: fieldInfo.field,
    );
    return editorBloc;
  }

  CellController makeCellControllerFromFieldId(String fieldId) {
    return makeCellController(
      _boardDataController,
      CellContext(fieldId: fieldId, rowId: rowInfos.last.rowId),
    );
  }

  Future<FieldEditorBloc> createField(FieldType fieldType) async {
    final editorBloc =
        await createFieldEditor(databaseController: _boardDataController);
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
}
