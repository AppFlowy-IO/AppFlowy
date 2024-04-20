import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;
  late FieldEditorBloc editorBloc;
  late BoardTestContext context;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
    context = await boardTest.createTestBoard();
    final fieldInfo = context.singleSelectFieldContext();
    editorBloc = context.makeFieldEditor(
      fieldInfo: fieldInfo,
    );

    await boardResponseFuture();
  });

  group('Group with not support grouping field', () {
    blocTest<FieldEditorBloc, FieldEditorState>(
      "switch to text field",
      build: () => editorBloc,
      wait: boardResponseDuration(),
      act: (bloc) async {
        bloc.add(const FieldEditorEvent.switchFieldType(FieldType.RichText));
      },
      verify: (bloc) {
        assert(bloc.state.field.fieldType == FieldType.RichText);
      },
    );
    blocTest<BoardBloc, BoardState>(
      'assert the number of groups is 1',
      build: () => BoardBloc(
        view: context.gridView,
        databaseController: DatabaseController(view: context.gridView),
      )..add(
          const BoardEvent.initial(),
        ),
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(
          bloc.groupControllers.values.length == 1,
          "Expected 1, but receive ${bloc.groupControllers.values.length}",
        );
      },
    );
  });
}
