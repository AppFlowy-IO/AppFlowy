import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest cellTest;

  setUpAll(() async {
    cellTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('select cell bloc:', () {
    late GridTestContext context;
    late SelectOptionCellController cellController;

    setUp(() async {
      context = await cellTest.makeDefaultTestGrid();
      await RowBackendService.createRow(viewId: context.viewId);
      final fieldIndex = context.fieldController.fieldInfos
          .indexWhere((field) => field.fieldType == FieldType.SingleSelect);
      cellController = context.makeGridCellController(fieldIndex, 0).as();
    });

    test('create options', () async {
      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();

      expect(bloc.state.options.length, 1);
      expect(bloc.state.options[0].name, "A");
    });

    test('update options', () async {
      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();

      final SelectOptionPB optionUpdate = bloc.state.options[0]
        ..color = SelectOptionColorPB.Aqua
        ..name = "B";
      bloc.add(SelectOptionCellEditorEvent.updateOption(optionUpdate));

      expect(bloc.state.options.length, 1);
      expect(bloc.state.options[0].name, "B");
      expect(bloc.state.options[0].color, SelectOptionColorPB.Aqua);
    });

    test('delete options', () async {
      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();
      assert(
        bloc.state.options.length == 1,
        "Expect 1 but receive ${bloc.state.options.length}, Options: ${bloc.state.options}",
      );

      bloc.add(const SelectOptionCellEditorEvent.filterOption("B"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();
      assert(
        bloc.state.options.length == 2,
        "Expect 2 but receive ${bloc.state.options.length}, Options: ${bloc.state.options}",
      );

      bloc.add(const SelectOptionCellEditorEvent.filterOption("C"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();
      assert(
        bloc.state.options.length == 3,
        "Expect 3 but receive ${bloc.state.options.length}. Options: ${bloc.state.options}",
      );

      bloc.add(SelectOptionCellEditorEvent.deleteOption(bloc.state.options[0]));
      await gridResponseFuture();
      assert(
        bloc.state.options.length == 2,
        "Expect 2 but receive ${bloc.state.options.length}. Options: ${bloc.state.options}",
      );

      bloc.add(const SelectOptionCellEditorEvent.deleteAllOptions());
      await gridResponseFuture();

      assert(
        bloc.state.options.isEmpty,
        "Expect empty but receive ${bloc.state.options.length}. Options: ${bloc.state.options}",
      );
    });

    test('select/unselect option', () async {
      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();

      final optionId = bloc.state.options[0].id;
      bloc.add(SelectOptionCellEditorEvent.unselectOption(optionId));
      await gridResponseFuture();
      assert(bloc.state.selectedOptions.isEmpty);

      bloc.add(SelectOptionCellEditorEvent.selectOption(optionId));
      await gridResponseFuture();

      assert(bloc.state.selectedOptions.length == 1);
      expect(bloc.state.selectedOptions[0].name, "A");
    });

    test('select an option or create one', () async {
      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("B"));
      bloc.add(const SelectOptionCellEditorEvent.submitTextField());
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
      bloc.add(const SelectOptionCellEditorEvent.submitTextField());
      await gridResponseFuture();

      expect(bloc.state.selectedOptions.length, 1);
      expect(bloc.state.options.length, 1);
      expect(bloc.state.selectedOptions[0].name, "A");
    });

    test('select multiple options', () async {
      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("B"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();

      bloc.add(
        const SelectOptionCellEditorEvent.selectMultipleOptions(
          ["A", "B", "C"],
          "x",
        ),
      );
      await gridResponseFuture();

      assert(bloc.state.selectedOptions.length == 1);
      expect(bloc.state.selectedOptions[0].name, "A");
      expect(bloc.filter, "x");
    });

    test('filter options', () async {
      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      await gridResponseFuture();

      bloc.add(const SelectOptionCellEditorEvent.filterOption("abcd"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();
      expect(
        bloc.state.options.length,
        1,
        reason: "Options: ${bloc.state.options}",
      );

      bloc.add(const SelectOptionCellEditorEvent.filterOption("aaaa"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();
      expect(
        bloc.state.options.length,
        2,
        reason: "Options: ${bloc.state.options}",
      );

      bloc.add(const SelectOptionCellEditorEvent.filterOption("defg"));
      bloc.add(const SelectOptionCellEditorEvent.createOption());
      await gridResponseFuture();
      expect(
        bloc.state.options.length,
        3,
        reason: "Options: ${bloc.state.options}",
      );

      bloc.add(const SelectOptionCellEditorEvent.filterOption("a"));
      await gridResponseFuture();

      expect(
        bloc.state.options.length,
        2,
        reason: "Options: ${bloc.state.options}",
      );
      expect(
        bloc.allOptions.length,
        3,
        reason: "Options: ${bloc.state.options}",
      );
      expect(bloc.state.createSelectOptionSuggestion!.name, "a");
      expect(bloc.filter, "a");
    });
  });
}
