import 'package:app_flowy/plugins/grid/application/field/field_action_sheet_bloc.dart';
import 'package:app_flowy/plugins/grid/application/grid_header_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('$GridHeaderBloc', () {
    late FieldActionSheetBloc actionSheetBloc;
    setUp(() async {
      await gridTest.createTestGrid();
      actionSheetBloc = FieldActionSheetBloc(
        fieldCellContext: gridTest.singleSelectFieldCellContext(),
      );
    });

    blocTest<GridHeaderBloc, GridHeaderState>(
      "hides property",
      build: () {
        final bloc = GridHeaderBloc(
          gridId: gridTest.gridView.id,
          fieldController: gridTest.fieldController,
        )..add(const GridHeaderEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        actionSheetBloc.add(const FieldActionSheetEvent.hideField());
        await Future.delayed(gridResponseDuration());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.fields.length == 2);
      },
    );

    blocTest<GridHeaderBloc, GridHeaderState>(
      "shows property",
      build: () {
        final bloc = GridHeaderBloc(
          gridId: gridTest.gridView.id,
          fieldController: gridTest.fieldController,
        )..add(const GridHeaderEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        actionSheetBloc.add(const FieldActionSheetEvent.hideField());
        await Future.delayed(gridResponseDuration());
        actionSheetBloc.add(const FieldActionSheetEvent.showField());
        await Future.delayed(gridResponseDuration());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.fields.length == 3);
      },
    );

    blocTest<GridHeaderBloc, GridHeaderState>(
      "duplicate property",
      build: () {
        final bloc = GridHeaderBloc(
          gridId: gridTest.gridView.id,
          fieldController: gridTest.fieldController,
        )..add(const GridHeaderEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        actionSheetBloc.add(const FieldActionSheetEvent.duplicateField());
        await Future.delayed(gridResponseDuration());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.fields.length == 4);
      },
    );

    blocTest<GridHeaderBloc, GridHeaderState>(
      "delete property",
      build: () {
        final bloc = GridHeaderBloc(
          gridId: gridTest.gridView.id,
          fieldController: gridTest.fieldController,
        )..add(const GridHeaderEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        actionSheetBloc.add(const FieldActionSheetEvent.deleteField());
        await Future.delayed(gridResponseDuration());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.fields.length == 2);
      },
    );

    blocTest<GridHeaderBloc, GridHeaderState>(
      "update name",
      build: () {
        final bloc = GridHeaderBloc(
          gridId: gridTest.gridView.id,
          fieldController: gridTest.fieldController,
        )..add(const GridHeaderEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        actionSheetBloc
            .add(const FieldActionSheetEvent.updateFieldName("Hello world"));
        await Future.delayed(gridResponseDuration());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        final field = bloc.state.fields.firstWhere(
            (element) => element.id == actionSheetBloc.fieldService.fieldId);

        assert(field.name == "Hello world");
      },
    );
  });
}
