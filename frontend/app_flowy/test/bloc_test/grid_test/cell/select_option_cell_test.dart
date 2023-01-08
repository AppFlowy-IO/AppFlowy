import 'package:app_flowy/plugins/grid/application/cell/select_option_editor_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import '../util.dart';

void main() {
  late AppFlowyGridCellTest cellTest;
  setUpAll(() async {
    cellTest = await AppFlowyGridCellTest.ensureInitialized();
  });

  group('SingleSelectOptionBloc', () {
    test('create options', () async {
      await cellTest.createTestGrid();
      await cellTest.createTestRow();
      final cellController = await cellTest.makeSelectOptionCellController(
          FieldType.SingleSelect, 0);

      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      bloc.add(const SelectOptionEditorEvent.initial());
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("A"));
      await gridResponseFuture();

      expect(bloc.state.options.length, 1);
      expect(bloc.state.options[0].name, "A");
    });

    test('update options', () async {
      await cellTest.createTestGrid();
      await cellTest.createTestRow();
      final cellController = await cellTest.makeSelectOptionCellController(
          FieldType.SingleSelect, 0);

      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      bloc.add(const SelectOptionEditorEvent.initial());
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("A"));
      await gridResponseFuture();

      SelectOptionPB optionUpdate = bloc.state.options[0]
        ..color = SelectOptionColorPB.Aqua
        ..name = "B";
      bloc.add(SelectOptionEditorEvent.updateOption(optionUpdate));

      expect(bloc.state.options.length, 1);
      expect(bloc.state.options[0].name, "B");
      expect(bloc.state.options[0].color, SelectOptionColorPB.Aqua);
    });

    test('delete options', () async {
      await cellTest.createTestGrid();
      await cellTest.createTestRow();
      final cellController = await cellTest.makeSelectOptionCellController(
          FieldType.SingleSelect, 0);

      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      bloc.add(const SelectOptionEditorEvent.initial());
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("A"));
      await gridResponseFuture();
      bloc.add(const SelectOptionEditorEvent.newOption("B"));
      await gridResponseFuture();
      bloc.add(const SelectOptionEditorEvent.newOption("C"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.deleteAllOptions());
      await gridResponseFuture();

      assert(bloc.state.options.isEmpty);
    });

    test('select/unselect option', () async {
      await cellTest.createTestGrid();
      await cellTest.createTestRow();
      final cellController = await cellTest.makeSelectOptionCellController(
          FieldType.SingleSelect, 0);

      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      bloc.add(const SelectOptionEditorEvent.initial());
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("A"));
      await gridResponseFuture();

      final optionId = bloc.state.options[0].id;
      bloc.add(SelectOptionEditorEvent.unSelectOption(optionId));
      await gridResponseFuture();
      assert(bloc.state.selectedOptions.isEmpty);

      bloc.add(SelectOptionEditorEvent.selectOption(optionId));
      await gridResponseFuture();

      assert(bloc.state.selectedOptions.length == 1);
      expect(bloc.state.selectedOptions[0].name, "A");
    });

    test('select an option or create one', () async {
      await cellTest.createTestGrid();
      await cellTest.createTestRow();
      final cellController = await cellTest.makeSelectOptionCellController(
          FieldType.SingleSelect, 0);

      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      bloc.add(const SelectOptionEditorEvent.initial());
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("A"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.trySelectOption("B"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.trySelectOption("A"));
      await gridResponseFuture();

      assert(bloc.state.selectedOptions.length == 1);
      assert(bloc.state.options.length == 2);
      expect(bloc.state.selectedOptions[0].name, "A");
    });

    test('select multiple options', () async {
      await cellTest.createTestGrid();
      await cellTest.createTestRow();
      final cellController = await cellTest.makeSelectOptionCellController(
          FieldType.SingleSelect, 0);

      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      bloc.add(const SelectOptionEditorEvent.initial());
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("A"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("B"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.selectMultipleOptions(
          ["A", "B", "C"], "x"));
      await gridResponseFuture();

      assert(bloc.state.selectedOptions.length == 1);
      expect(bloc.state.selectedOptions[0].name, "A");
      expect(bloc.state.filter, const Some("x"));
    });

    test('filter options', () async {
      await cellTest.createTestGrid();
      await cellTest.createTestRow();
      final cellController = await cellTest.makeSelectOptionCellController(
          FieldType.SingleSelect, 0);

      final bloc = SelectOptionCellEditorBloc(cellController: cellController);
      bloc.add(const SelectOptionEditorEvent.initial());
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("abcd"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("aaaa"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.newOption("defg"));
      await gridResponseFuture();

      bloc.add(const SelectOptionEditorEvent.filterOption("a"));
      await gridResponseFuture();

      expect(bloc.state.options.length, 2);
      expect(bloc.state.allOptions.length, 3);
      expect(bloc.state.createOption, const Some("a"));
      expect(bloc.state.filter, const Some("a"));
    });
  });
}
