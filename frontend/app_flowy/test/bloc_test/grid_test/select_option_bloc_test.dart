import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/select_option_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'util.dart';

void main() {
  late AppFlowyGridSelectOptionCellTest cellTest;
  setUpAll(() async {
    cellTest = await AppFlowyGridSelectOptionCellTest.ensureInitialized();
  });

  group('SingleSelectOptionBloc', () {
    late GridSelectOptionCellController cellController;
    setUp(() async {
      cellController =
          await cellTest.makeCellController(FieldType.SingleSelect);
    });

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "delete options",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const SelectOptionEditorEvent.newOption("A"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.newOption("B"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.newOption("C"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.deleteAllOptions());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.options.isEmpty);
      },
    );

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "create option",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        _removeFieldOptions(bloc);
        bloc.add(const SelectOptionEditorEvent.newOption("A"));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        expect(bloc.state.options.length, 1);
        expect(bloc.state.options[0].name, "A");
      },
    );

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "delete option",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        _removeFieldOptions(bloc);
        bloc.add(const SelectOptionEditorEvent.newOption("A"));
        await Future.delayed(gridResponseDuration());
        bloc.add(SelectOptionEditorEvent.deleteOption(bloc.state.options[0]));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.options.isEmpty);
      },
    );

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "update option",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        _removeFieldOptions(bloc);
        bloc.add(const SelectOptionEditorEvent.newOption("A"));
        await Future.delayed(gridResponseDuration());
        SelectOptionPB optionUpdate = bloc.state.options[0]
          ..color = SelectOptionColorPB.Aqua
          ..name = "B";
        bloc.add(SelectOptionEditorEvent.updateOption(optionUpdate));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.options.length == 1);
        expect(bloc.state.options[0].color, SelectOptionColorPB.Aqua);
        expect(bloc.state.options[0].name, "B");
      },
    );

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "select/unselect option",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        _removeFieldOptions(bloc);
        bloc.add(const SelectOptionEditorEvent.newOption("A"));
        await Future.delayed(gridResponseDuration());
        expect(bloc.state.selectedOptions.length, 1);
        final optionId = bloc.state.options[0].id;
        bloc.add(SelectOptionEditorEvent.unSelectOption(optionId));
        await Future.delayed(gridResponseDuration());
        assert(bloc.state.selectedOptions.isEmpty);
        bloc.add(SelectOptionEditorEvent.selectOption(optionId));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.selectedOptions.length == 1);
        expect(bloc.state.selectedOptions[0].name, "A");
      },
    );

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "select an option or create one",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        _removeFieldOptions(bloc);
        bloc.add(const SelectOptionEditorEvent.newOption("A"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.trySelectOption("B"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.trySelectOption("A"));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.selectedOptions.length == 1);
        assert(bloc.state.options.length == 2);
        expect(bloc.state.selectedOptions[0].name, "A");
      },
    );

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "select multiple options",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        _removeFieldOptions(bloc);
        bloc.add(const SelectOptionEditorEvent.newOption("A"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.newOption("B"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.selectMultipleOptions(
            ["A", "B", "C"], "x"));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.selectedOptions.length == 1);
        expect(bloc.state.selectedOptions[0].name, "A");
        expect(bloc.state.filter, const Some("x"));
      },
    );

    blocTest<SelectOptionCellEditorBloc, SelectOptionEditorState>(
      "filter options",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        _removeFieldOptions(bloc);
        bloc.add(const SelectOptionEditorEvent.newOption("abcd"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.newOption("aaaa"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.newOption("defg"));
        await Future.delayed(gridResponseDuration());
        bloc.add(const SelectOptionEditorEvent.filterOption("a"));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        expect(bloc.state.options.length, 2);
        expect(bloc.state.allOptions.length, 3);
        expect(bloc.state.createOption, const Some("a"));
        expect(bloc.state.filter, const Some("a"));
      },
    );
  });
}

void _removeFieldOptions(SelectOptionCellEditorBloc bloc) async {
  if (bloc.state.options.isNotEmpty) {
    bloc.add(const SelectOptionEditorEvent.deleteAllOptions());
    await Future.delayed(gridResponseDuration());
  }
}
