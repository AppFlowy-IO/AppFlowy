import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/grid/application/sort/sort_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('sort editor bloc:', () {
    late GridTestContext context;
    late SortEditorBloc sortBloc;

    setUp(() async {
      context = await gridTest.makeDefaultTestGrid();
      sortBloc = SortEditorBloc(
        viewId: context.view.id,
        fieldController: context.fieldController,
      );
    });

    FieldInfo getFirstFieldByType(FieldType fieldType) {
      return context.fieldController.fieldInfos
          .firstWhere((field) => field.fieldType == fieldType);
    }

    test('create sort', () async {
      expect(sortBloc.state.sorts.length, equals(0));
      expect(sortBloc.state.creatableFields.length, equals(3));
      expect(sortBloc.state.allFields.length, equals(3));

      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      sortBloc.add(SortEditorEvent.createSort(fieldId: selectOptionField.id));
      await gridResponseFuture();
      expect(sortBloc.state.sorts.length, 1);
      expect(sortBloc.state.sorts.first.fieldId, selectOptionField.id);
      expect(
        sortBloc.state.sorts.first.condition,
        SortConditionPB.Ascending,
      );
      expect(sortBloc.state.creatableFields.length, equals(2));
      expect(sortBloc.state.allFields.length, equals(3));
    });

    test('change sort field', () async {
      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      sortBloc.add(SortEditorEvent.createSort(fieldId: selectOptionField.id));
      await gridResponseFuture();

      expect(
        sortBloc.state.creatableFields
            .map((e) => e.id)
            .contains(selectOptionField.id),
        false,
      );

      final checkboxField = getFirstFieldByType(FieldType.Checkbox);
      sortBloc.add(
        SortEditorEvent.editSort(
          sortId: sortBloc.state.sorts.first.sortId,
          fieldId: checkboxField.id,
        ),
      );
      await gridResponseFuture();

      expect(sortBloc.state.creatableFields.length, equals(2));
      expect(
        sortBloc.state.creatableFields
            .map((e) => e.id)
            .contains(checkboxField.id),
        false,
      );
    });

    test('update sort direction', () async {
      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      sortBloc.add(SortEditorEvent.createSort(fieldId: selectOptionField.id));
      await gridResponseFuture();

      expect(
        sortBloc.state.sorts.first.condition,
        SortConditionPB.Ascending,
      );

      sortBloc.add(
        SortEditorEvent.editSort(
          sortId: sortBloc.state.sorts.first.sortId,
          condition: SortConditionPB.Descending,
        ),
      );
      await gridResponseFuture();

      expect(
        sortBloc.state.sorts.first.condition,
        SortConditionPB.Descending,
      );
    });

    for (int i = 0; i < 50; i++) {
      test('reorder sorts', () async {
        final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
        final checkboxField = getFirstFieldByType(FieldType.Checkbox);
        sortBloc
          ..add(SortEditorEvent.createSort(fieldId: selectOptionField.id))
          ..add(SortEditorEvent.createSort(fieldId: checkboxField.id));
        await gridResponseFuture();

        expect(sortBloc.state.sorts[0].fieldId, selectOptionField.id);
        expect(sortBloc.state.sorts[1].fieldId, checkboxField.id);
        expect(sortBloc.state.creatableFields.length, equals(1));
        expect(sortBloc.state.allFields.length, equals(3));

        sortBloc.add(
          const SortEditorEvent.reorderSort(0, 2),
        );
        await gridResponseFuture();

        expect(sortBloc.state.sorts[0].fieldId, checkboxField.id);
        expect(sortBloc.state.sorts[1].fieldId, selectOptionField.id);
        expect(sortBloc.state.creatableFields.length, equals(1));
        expect(sortBloc.state.allFields.length, equals(3));
      });
    }

    test('delete sort', () async {
      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      sortBloc.add(SortEditorEvent.createSort(fieldId: selectOptionField.id));
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, 1);

      sortBloc.add(
        SortEditorEvent.deleteSort(sortBloc.state.sorts.first.sortId),
      );
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, 0);
      expect(sortBloc.state.creatableFields.length, equals(3));
      expect(sortBloc.state.allFields.length, equals(3));
    });

    test('delete all sorts', () async {
      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      final checkboxField = getFirstFieldByType(FieldType.Checkbox);
      sortBloc
        ..add(SortEditorEvent.createSort(fieldId: selectOptionField.id))
        ..add(SortEditorEvent.createSort(fieldId: checkboxField.id));
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, 2);

      sortBloc.add(const SortEditorEvent.deleteAllSorts());
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, 0);
      expect(sortBloc.state.creatableFields.length, equals(3));
      expect(sortBloc.state.allFields.length, equals(3));
    });

    test('update sort field', () async {
      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      sortBloc.add(SortEditorEvent.createSort(fieldId: selectOptionField.id));
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, equals(1));

      // edit field
      await FieldBackendService(
        viewId: context.view.id,
        fieldId: selectOptionField.id,
      ).updateField(name: "HERRO");
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, equals(1));
      expect(sortBloc.state.allFields[1].name, "HERRO");

      expect(sortBloc.state.creatableFields.length, equals(2));
      expect(sortBloc.state.allFields.length, equals(3));
    });

    test('delete sorting field', () async {
      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      sortBloc.add(SortEditorEvent.createSort(fieldId: selectOptionField.id));
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, equals(1));

      // edit field
      await FieldBackendService(
        viewId: context.view.id,
        fieldId: selectOptionField.id,
      ).delete();
      await gridResponseFuture();

      expect(sortBloc.state.sorts.length, equals(0));
      expect(sortBloc.state.creatableFields.length, equals(2));
      expect(sortBloc.state.allFields.length, equals(2));
    });
  });
}
