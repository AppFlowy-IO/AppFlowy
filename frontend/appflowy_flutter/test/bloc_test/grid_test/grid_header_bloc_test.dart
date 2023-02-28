import 'package:appflowy/plugins/database_view/application/field/field_action_sheet_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_header_bloc.dart';
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
    late GridTestContext context;
    setUp(() async {
      context = await gridTest.createTestGrid();
      actionSheetBloc = FieldActionSheetBloc(
        fieldCellContext: context.singleSelectFieldCellContext(),
      );
    });

    blocTest<GridHeaderBloc, GridHeaderState>(
      "hides property",
      build: () {
        final bloc = GridHeaderBloc(
          viewId: context.gridView.id,
          fieldController: context.fieldController,
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
          viewId: context.gridView.id,
          fieldController: context.fieldController,
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
          viewId: context.gridView.id,
          fieldController: context.fieldController,
        )..add(const GridHeaderEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        actionSheetBloc.add(const FieldActionSheetEvent.duplicateField());
        await Future.delayed(gridResponseDuration());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        expect(bloc.state.fields.length, 4);
      },
    );

    blocTest<GridHeaderBloc, GridHeaderState>(
      "delete property",
      build: () {
        final bloc = GridHeaderBloc(
          viewId: context.gridView.id,
          fieldController: context.fieldController,
        )..add(const GridHeaderEvent.initial());
        return bloc;
      },
      act: (bloc) async {
        actionSheetBloc.add(const FieldActionSheetEvent.deleteField());
        await Future.delayed(gridResponseDuration());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        expect(bloc.state.fields.length, 2);
      },
    );

    blocTest<GridHeaderBloc, GridHeaderState>(
      "update name",
      build: () {
        final bloc = GridHeaderBloc(
          viewId: context.gridView.id,
          fieldController: context.fieldController,
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

        expect(field.name, "Hello world");
      },
    );
  });
}
