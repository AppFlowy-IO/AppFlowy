import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/setting/group_bloc.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  test('group by date field test', () async {
    final context = await boardTest.createTestBoard();
    final boardBloc = BoardBloc(
      databaseController: DatabaseController(view: context.gridView),
    )..add(const BoardEvent.initial());
    await boardResponseFuture();

    // assert the initial values
    assert(boardBloc.groupControllers.values.length == 4);
    assert(context.fieldContexts.length == 2);

    await context.createField(FieldType.DateTime);
    await boardResponseFuture();
    assert(context.fieldContexts.length == 3);

    final dateField = context.fieldContexts.last.field;
    final cellController = context.makeCellControllerFromFieldId(dateField.id)
        as DateCellController;
    final bloc = DateCellEditorBloc(
      cellController: cellController,
      reminderBloc: getIt<ReminderBloc>(),
    );
    await boardResponseFuture();

    bloc.add(DateCellEditorEvent.selectDay(DateTime.now()));
    await boardResponseFuture();

    final gridGroupBloc = DatabaseGroupBloc(
      viewId: context.gridView.id,
      databaseController: context.databaseController,
    )..add(const DatabaseGroupEvent.initial());
    gridGroupBloc.add(
      DatabaseGroupEvent.setGroupByField(
        dateField.id,
        dateField.fieldType,
      ),
    );
    await boardResponseFuture();

    assert(boardBloc.groupControllers.values.length == 2);
    assert(
      boardBloc.boardController.groupDatas.last.headerData.groupName ==
          LocaleKeys.board_dateCondition_today.tr(),
    );
  });

  test('group by date field with condition', () async {
    final context = await boardTest.createTestBoard();
    final boardBloc = BoardBloc(
      databaseController: DatabaseController(view: context.gridView),
    )..add(const BoardEvent.initial());
    await boardResponseFuture();

    // assert the initial values
    assert(boardBloc.groupControllers.values.length == 4);
    assert(context.fieldContexts.length == 2);

    await context.createField(FieldType.DateTime);
    await boardResponseFuture();
    assert(context.fieldContexts.length == 3);

    final dateField = context.fieldContexts.last.field;
    final cellController = context.makeCellControllerFromFieldId(dateField.id)
        as DateCellController;
    final bloc = DateCellEditorBloc(
      cellController: cellController,
      reminderBloc: getIt<ReminderBloc>(),
    );
    await boardResponseFuture();

    bloc.add(DateCellEditorEvent.selectDay(DateTime.now()));
    await boardResponseFuture();

    final gridGroupBloc = DatabaseGroupBloc(
      viewId: context.gridView.id,
      databaseController: context.databaseController,
    )..add(const DatabaseGroupEvent.initial());
    final settingContent = DateGroupConfigurationPB()
      ..condition = DateConditionPB.Year;
    gridGroupBloc.add(
      DatabaseGroupEvent.setGroupByField(
        dateField.id,
        dateField.fieldType,
        settingContent.writeToBuffer(),
      ),
    );
    await boardResponseFuture();

    assert(boardBloc.groupControllers.values.length == 2);
    assert(
      boardBloc.boardController.groupDatas.last.headerData.groupName == "2024",
    );
  });
}
