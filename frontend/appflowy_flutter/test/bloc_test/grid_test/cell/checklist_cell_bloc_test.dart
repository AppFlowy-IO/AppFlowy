import 'package:appflowy/plugins/database/application/cell/bloc/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest cellTest;

  setUpAll(() async {
    cellTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('checklist cell bloc:', () {
    late GridTestContext context;
    late ChecklistCellController cellController;

    setUp(() async {
      context = await cellTest.makeDefaultTestGrid();
      await FieldBackendService.createField(
        viewId: context.viewId,
        fieldType: FieldType.Checklist,
      );
      await gridResponseFuture();
      final fieldIndex = context.fieldController.fieldInfos
          .indexWhere((field) => field.fieldType == FieldType.Checklist);
      cellController = context.makeGridCellController(fieldIndex, 0).as();
    });

    test('create tasks', () async {
      final bloc = ChecklistCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 0);

      bloc.add(const ChecklistCellEvent.createNewTask("B"));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 1);

      bloc.add(const ChecklistCellEvent.createNewTask("A", index: 0));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 2);
      expect(bloc.state.tasks.first.data.name, "A");
      expect(bloc.state.tasks.last.data.name, "B");
    });

    test('rename task', () async {
      final bloc = ChecklistCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 0);

      bloc.add(const ChecklistCellEvent.createNewTask("B"));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 1);
      expect(bloc.state.tasks.first.data.name, "B");

      bloc.add(
        ChecklistCellEvent.updateTaskName(bloc.state.tasks.first.data, "A"),
      );
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 1);
      expect(bloc.state.tasks.first.data.name, "A");
    });

    test('select task', () async {
      final bloc = ChecklistCellBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const ChecklistCellEvent.createNewTask("A"));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 1);
      expect(bloc.state.tasks.first.isSelected, false);

      bloc.add(const ChecklistCellEvent.selectTask('A'));
      await gridResponseFuture();

      expect(bloc.state.tasks.first.isSelected, false);

      bloc.add(
        ChecklistCellEvent.selectTask(bloc.state.tasks.first.data.id),
      );
      await gridResponseFuture();

      expect(bloc.state.tasks.first.isSelected, true);
    });

    test('delete task', () async {
      final bloc = ChecklistCellBloc(cellController: cellController);
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 0);

      bloc.add(const ChecklistCellEvent.createNewTask("A"));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 1);
      expect(bloc.state.tasks.first.isSelected, false);

      bloc.add(const ChecklistCellEvent.deleteTask('A'));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 1);

      bloc.add(
        ChecklistCellEvent.deleteTask(bloc.state.tasks.first.data.id),
      );
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 0);
    });

    test('reorder task', () async {
      final bloc = ChecklistCellBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const ChecklistCellEvent.createNewTask("A"));
      await gridResponseFuture();
      bloc.add(const ChecklistCellEvent.createNewTask("B"));
      await gridResponseFuture();
      bloc.add(const ChecklistCellEvent.createNewTask("C"));
      await gridResponseFuture();
      bloc.add(const ChecklistCellEvent.createNewTask("D"));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 4);

      bloc.add(const ChecklistCellEvent.reorderTask(0, 2));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 4);
      expect(bloc.state.tasks[0].data.name, "B");
      expect(bloc.state.tasks[1].data.name, "A");
      expect(bloc.state.tasks[2].data.name, "C");
      expect(bloc.state.tasks[3].data.name, "D");

      bloc.add(const ChecklistCellEvent.reorderTask(3, 1));
      await gridResponseFuture();

      expect(bloc.state.tasks.length, 4);
      expect(bloc.state.tasks[0].data.name, "B");
      expect(bloc.state.tasks[1].data.name, "D");
      expect(bloc.state.tasks[2].data.name, "A");
      expect(bloc.state.tasks[3].data.name, "C");
    });
  });
}
