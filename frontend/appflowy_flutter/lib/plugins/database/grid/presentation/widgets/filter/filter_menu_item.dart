import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter/material.dart';

import 'choicechip/checkbox.dart';
import 'choicechip/checklist/checklist.dart';
import 'choicechip/date.dart';
import 'choicechip/number.dart';
import 'choicechip/select_option/select_option.dart';
import 'choicechip/text.dart';
import 'choicechip/url.dart';
import 'choicechip/time.dart';
import 'filter_info.dart';

class FilterMenuItem extends StatelessWidget {
  const FilterMenuItem({required this.filterInfo, super.key});

  final FilterInfo filterInfo;

  @override
  Widget build(BuildContext context) {
    return switch (filterInfo.fieldInfo.fieldType) {
      FieldType.Checkbox => CheckboxFilterChoicechip(filterInfo: filterInfo),
      FieldType.DateTime => DateFilterChoicechip(filterInfo: filterInfo),
      FieldType.MultiSelect =>
        SelectOptionFilterChoicechip(filterInfo: filterInfo),
      FieldType.Number =>
        NumberFilterChoiceChip(filterInfo: filterInfo),
      FieldType.RichText => TextFilterChoicechip(filterInfo: filterInfo),
      FieldType.SingleSelect =>
        SelectOptionFilterChoicechip(filterInfo: filterInfo),
      FieldType.URL => URLFilterChoiceChip(filterInfo: filterInfo),
      FieldType.Checklist => ChecklistFilterChoicechip(filterInfo: filterInfo),
      FieldType.Time =>
        TimeFilterChoiceChip(filterInfo: filterInfo),
      _ => const SizedBox(),
    };
  }
}
