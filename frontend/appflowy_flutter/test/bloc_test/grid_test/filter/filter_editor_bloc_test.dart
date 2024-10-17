import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('filter editor bloc:', () {
    late GridTestContext context;
    late FilterEditorBloc filterBloc;

    setUp(() async {
      context = await gridTest.makeDefaultTestGrid();
      filterBloc = FilterEditorBloc(
        viewId: context.viewId,
        fieldController: context.fieldController,
      );
    });

    FieldInfo getFirstFieldByType(FieldType fieldType) {
      return context.fieldController.fieldInfos
          .firstWhere((field) => field.fieldType == fieldType);
    }

    test('create filter', () async {
      expect(filterBloc.state.filters.length, equals(0));
      expect(filterBloc.state.fields.length, equals(3));

      // through domain directly
      final textField = getFirstFieldByType(FieldType.RichText);
      final service = FilterBackendService(viewId: context.viewId);
      await service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterConditionPB.TextIsEmpty,
        content: "",
      );
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(1));
      expect(filterBloc.state.fields.length, equals(3));

      // through bloc event
      final selectOptionField = getFirstFieldByType(FieldType.SingleSelect);
      filterBloc.add(FilterEditorEvent.createFilter(selectOptionField));
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(2));
      expect(filterBloc.state.filters.first.fieldId, equals(textField.id));
      expect(filterBloc.state.filters[1].fieldId, equals(selectOptionField.id));

      final filter = filterBloc.state.filters.first as TextFilter;
      expect(filter.condition, equals(TextFilterConditionPB.TextIsEmpty));
      expect(filter.content, equals(""));
      final filter2 = filterBloc.state.filters[1] as SelectOptionFilter;
      expect(filter2.condition, equals(SelectOptionFilterConditionPB.OptionIs));
      expect(filter2.optionIds.length, equals(0));
      expect(filterBloc.state.fields.length, equals(3));
    });

    test('change filtering field', () async {
      final textField = getFirstFieldByType(FieldType.RichText);
      final selectField = getFirstFieldByType(FieldType.Checkbox);
      filterBloc.add(FilterEditorEvent.createFilter(textField));
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(1));
      expect(filterBloc.state.fields.length, equals(3));
      expect(
        filterBloc.state.filters.first.fieldType,
        equals(FieldType.RichText),
      );

      final filter = filterBloc.state.filters.first;
      filterBloc.add(
        FilterEditorEvent.changeFilteringField(filter.filterId, selectField),
      );
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(1));
      expect(
        filterBloc.state.filters.first.fieldType,
        equals(FieldType.Checkbox),
      );
      expect(filterBloc.state.fields.length, equals(3));
    });

    test('delete filter', () async {
      final textField = getFirstFieldByType(FieldType.RichText);
      filterBloc.add(FilterEditorEvent.createFilter(textField));
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(1));
      expect(filterBloc.state.fields.length, equals(3));

      final filter = filterBloc.state.filters.first;
      filterBloc.add(FilterEditorEvent.deleteFilter(filter.filterId));
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(0));
      expect(filterBloc.state.fields.length, equals(3));
    });

    test('update filter', () async {
      final service = FilterBackendService(viewId: context.viewId);
      final textField = getFirstFieldByType(FieldType.RichText);

      // Create filter
      await service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterConditionPB.TextIsEmpty,
        content: "",
      );
      await gridResponseFuture();
      TextFilter filter = filterBloc.state.filters.first as TextFilter;
      expect(filter.condition, equals(TextFilterConditionPB.TextIsEmpty));

      final textFilter = context.fieldController.filters.first;

      // Update the existing filter
      await service.insertTextFilter(
        fieldId: textField.id,
        filterId: textFilter.filterId,
        condition: TextFilterConditionPB.TextIs,
        content: "ABC",
      );
      await gridResponseFuture();
      filter = filterBloc.state.filters.first as TextFilter;
      expect(filter.condition, equals(TextFilterConditionPB.TextIs));
      expect(filter.content, equals("ABC"));
    });

    test('update filtering field\'s name', () async {
      final textField = getFirstFieldByType(FieldType.RichText);
      filterBloc.add(FilterEditorEvent.createFilter(textField));
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(1));

      expect(filterBloc.state.fields.length, equals(3));
      expect(filterBloc.state.fields.first.name, equals("Name"));

      // edit field
      await FieldBackendService(
        viewId: context.viewId,
        fieldId: textField.id,
      ).updateField(name: "New Name");
      await gridResponseFuture();
      expect(filterBloc.state.fields.length, equals(3));
      expect(filterBloc.state.fields.first.name, equals("New Name"));
    });

    test('update field type', () async {
      final checkboxField = getFirstFieldByType(FieldType.Checkbox);
      filterBloc.add(FilterEditorEvent.createFilter(checkboxField));
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(1));

      // edit field
      await FieldBackendService(
        viewId: context.viewId,
        fieldId: checkboxField.id,
      ).updateType(fieldType: FieldType.DateTime);
      await gridResponseFuture();

      // filter is removed
      expect(filterBloc.state.filters.length, equals(0));
      expect(filterBloc.state.fields.length, equals(3));
      expect(filterBloc.state.fields[2].fieldType, FieldType.DateTime);
    });

    test('update filter field', () async {
      final checkboxField = getFirstFieldByType(FieldType.Checkbox);
      filterBloc.add(FilterEditorEvent.createFilter(checkboxField));
      await gridResponseFuture();
      expect(filterBloc.state.filters.length, equals(1));

      // edit field
      await FieldBackendService(
        viewId: context.viewId,
        fieldId: checkboxField.id,
      ).updateField(name: "HERRO");
      await gridResponseFuture();

      expect(filterBloc.state.filters.length, equals(1));
      expect(filterBloc.state.fields.length, equals(3));
      expect(filterBloc.state.fields[2].name, "HERRO");
    });
  });
}
