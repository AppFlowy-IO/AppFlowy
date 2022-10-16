import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/select_option_editor_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
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
      "create option",
      build: () {
        final bloc = SelectOptionCellEditorBloc(cellController: cellController);
        bloc.add(const SelectOptionEditorEvent.initial());
        return bloc;
      },
      act: (bloc) => bloc.add(const SelectOptionEditorEvent.newOption("A")),
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.options.length == 1);
        assert(bloc.state.options[0].name == "A");
      },
    );
  });
}
