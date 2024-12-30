import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/setting/group_bloc.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  // Group by checkbox field
  test('group by checkbox field test', () async {
    final context = await boardTest.createTestBoard();
    final boardBloc = BoardBloc(
      databaseController: DatabaseController(view: context.gridView),
    )..add(const BoardEvent.initial());
    await boardResponseFuture();

    // assert the initial values
    assert(boardBloc.groupControllers.values.length == 4);
    assert(context.fieldContexts.length == 2);

    // create checkbox field
    await context.createField(FieldType.Checkbox);
    await boardResponseFuture();
    assert(context.fieldContexts.length == 3);

    // set group by checkbox
    final checkboxField = context.fieldContexts.last.field;
    final gridGroupBloc = DatabaseGroupBloc(
      viewId: context.gridView.id,
      databaseController: context.databaseController,
    )..add(const DatabaseGroupEvent.initial());
    gridGroupBloc.add(
      DatabaseGroupEvent.setGroupByField(
        checkboxField.id,
        checkboxField.fieldType,
      ),
    );
    await boardResponseFuture();

    assert(boardBloc.groupControllers.values.length == 2);
  });
}
