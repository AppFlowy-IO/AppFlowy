import 'dart:typed_data';

import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsing filter entities:', () {
    FilterPB createFilterPB(
      FieldType fieldType,
      Uint8List data,
    ) {
      return FilterPB(
        id: "FT",
        filterType: FilterType.Data,
        data: FilterDataPB(
          fieldId: "FD",
          fieldType: fieldType,
          data: data,
        ),
      );
    }

    test('text', () async {
      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.RichText,
            TextFilterPB(
              condition: TextFilterConditionPB.TextContains,
              content: "c",
            ).writeToBuffer(),
          ),
        ),
        equals(
          TextFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.RichText,
            condition: TextFilterConditionPB.TextContains,
            content: "c",
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.RichText,
            TextFilterPB(
              condition: TextFilterConditionPB.TextContains,
              content: "",
            ).writeToBuffer(),
          ),
        ),
        equals(
          TextFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.RichText,
            condition: TextFilterConditionPB.TextContains,
            content: "",
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.RichText,
            TextFilterPB(
              condition: TextFilterConditionPB.TextIsEmpty,
              content: "",
            ).writeToBuffer(),
          ),
        ),
        equals(
          TextFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.RichText,
            condition: TextFilterConditionPB.TextIsEmpty,
            content: "",
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.RichText,
            TextFilterPB(
              condition: TextFilterConditionPB.TextIsEmpty,
              content: "",
            ).writeToBuffer(),
          ),
        ),
        equals(
          TextFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.RichText,
            condition: TextFilterConditionPB.TextIsEmpty,
            content: "c",
          ),
        ),
      );
    });

    test('number', () async {
      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.Number,
            NumberFilterPB(
              condition: NumberFilterConditionPB.GreaterThan,
              content: "",
            ).writeToBuffer(),
          ),
        ),
        equals(
          NumberFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.Number,
            condition: NumberFilterConditionPB.GreaterThan,
            content: "",
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.Number,
            NumberFilterPB(
              condition: NumberFilterConditionPB.GreaterThan,
              content: "123",
            ).writeToBuffer(),
          ),
        ),
        equals(
          NumberFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.Number,
            condition: NumberFilterConditionPB.GreaterThan,
            content: "123",
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.Number,
            NumberFilterPB(
              condition: NumberFilterConditionPB.NumberIsEmpty,
              content: "",
            ).writeToBuffer(),
          ),
        ),
        equals(
          NumberFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.Number,
            condition: NumberFilterConditionPB.NumberIsEmpty,
            content: "",
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.Number,
            NumberFilterPB(
              condition: NumberFilterConditionPB.NumberIsEmpty,
              content: "",
            ).writeToBuffer(),
          ),
        ),
        equals(
          NumberFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.Number,
            condition: NumberFilterConditionPB.NumberIsEmpty,
            content: "123",
          ),
        ),
      );
    });

    test('checkbox', () async {
      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.Checkbox,
            CheckboxFilterPB(
              condition: CheckboxFilterConditionPB.IsChecked,
            ).writeToBuffer(),
          ),
        ),
        equals(
          const CheckboxFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.Checkbox,
            condition: CheckboxFilterConditionPB.IsChecked,
          ),
        ),
      );
    });

    test('checklist', () async {
      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.Checklist,
            ChecklistFilterPB(
              condition: ChecklistFilterConditionPB.IsComplete,
            ).writeToBuffer(),
          ),
        ),
        equals(
          const ChecklistFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.Checklist,
            condition: ChecklistFilterConditionPB.IsComplete,
          ),
        ),
      );
    });

    test('single select option', () async {
      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.SingleSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIs,
              optionIds: [],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.SingleSelect,
            condition: SelectOptionFilterConditionPB.OptionIs,
            optionIds: const [],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.SingleSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIs,
              optionIds: ['a'],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.SingleSelect,
            condition: SelectOptionFilterConditionPB.OptionIs,
            optionIds: const ['a'],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.SingleSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIs,
              optionIds: ['a', 'b'],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.SingleSelect,
            condition: SelectOptionFilterConditionPB.OptionIs,
            optionIds: const ['a', 'b'],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.SingleSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIsEmpty,
              optionIds: [],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.SingleSelect,
            condition: SelectOptionFilterConditionPB.OptionIsEmpty,
            optionIds: const [],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.SingleSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIsEmpty,
              optionIds: ['a'],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.SingleSelect,
            condition: SelectOptionFilterConditionPB.OptionIsEmpty,
            optionIds: const [],
          ),
        ),
      );
    });

    test('multi select option', () async {
      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.MultiSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionContains,
              optionIds: [],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.MultiSelect,
            condition: SelectOptionFilterConditionPB.OptionContains,
            optionIds: const [],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.MultiSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionContains,
              optionIds: ['a'],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.MultiSelect,
            condition: SelectOptionFilterConditionPB.OptionContains,
            optionIds: const ['a'],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.MultiSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionContains,
              optionIds: ['a', 'b'],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.MultiSelect,
            condition: SelectOptionFilterConditionPB.OptionContains,
            optionIds: const ['a', 'b'],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.MultiSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIs,
              optionIds: ['a', 'b'],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.MultiSelect,
            condition: SelectOptionFilterConditionPB.OptionIs,
            optionIds: const ['a', 'b'],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.MultiSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIsEmpty,
              optionIds: [],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.MultiSelect,
            condition: SelectOptionFilterConditionPB.OptionIsEmpty,
            optionIds: const [],
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.MultiSelect,
            SelectOptionFilterPB(
              condition: SelectOptionFilterConditionPB.OptionIsEmpty,
              optionIds: ['a'],
            ).writeToBuffer(),
          ),
        ),
        equals(
          SelectOptionFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.MultiSelect,
            condition: SelectOptionFilterConditionPB.OptionIsEmpty,
            optionIds: const [],
          ),
        ),
      );
    });

    test('date time', () {
      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.DateTime,
            DateFilterPB(
              condition: DateFilterConditionPB.DateStartsOn,
              timestamp: Int64(5),
            ).writeToBuffer(),
          ),
        ),
        equals(
          DateTimeFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.DateTime,
            condition: DateFilterConditionPB.DateStartsOn,
            timestamp: DateTime.fromMillisecondsSinceEpoch(5 * 1000),
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.DateTime,
            DateFilterPB(
              condition: DateFilterConditionPB.DateStartsOn,
            ).writeToBuffer(),
          ),
        ),
        equals(
          DateTimeFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.DateTime,
            condition: DateFilterConditionPB.DateStartsOn,
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.DateTime,
            DateFilterPB(
              condition: DateFilterConditionPB.DateStartsOn,
              start: Int64(5),
            ).writeToBuffer(),
          ),
        ),
        equals(
          DateTimeFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.DateTime,
            condition: DateFilterConditionPB.DateStartsOn,
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.DateTime,
            DateFilterPB(
              condition: DateFilterConditionPB.DateEndsBetween,
              start: Int64(5),
            ).writeToBuffer(),
          ),
        ),
        equals(
          DateTimeFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.DateTime,
            condition: DateFilterConditionPB.DateEndsBetween,
            start: DateTime.fromMillisecondsSinceEpoch(5 * 1000),
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.DateTime,
            DateFilterPB(
              condition: DateFilterConditionPB.DateEndIsNotEmpty,
            ).writeToBuffer(),
          ),
        ),
        equals(
          DateTimeFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.DateTime,
            condition: DateFilterConditionPB.DateEndIsNotEmpty,
          ),
        ),
      );

      expect(
        DatabaseFilter.fromPB(
          createFilterPB(
            FieldType.DateTime,
            DateFilterPB(
              condition: DateFilterConditionPB.DateEndIsNotEmpty,
              start: Int64(5),
              end: Int64(5),
              timestamp: Int64(5),
            ).writeToBuffer(),
          ),
        ),
        equals(
          DateTimeFilter(
            filterId: "FT",
            fieldId: "FD",
            fieldType: FieldType.DateTime,
            condition: DateFilterConditionPB.DateEndIsNotEmpty,
          ),
        ),
      );
    });
  });

  // group('write to buffer', () {
  //   test('text', () {});
  // });
}
