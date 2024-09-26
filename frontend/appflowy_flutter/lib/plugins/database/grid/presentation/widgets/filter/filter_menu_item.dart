import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/material.dart';

import 'choicechip/checkbox.dart';
import 'choicechip/checklist.dart';
import 'choicechip/date.dart';
import 'choicechip/number.dart';
import 'choicechip/select_option/select_option.dart';
import 'choicechip/text.dart';
import 'choicechip/url.dart';

class FilterMenuItem extends StatelessWidget {
  const FilterMenuItem({
    super.key,
    required this.fieldType,
    required this.filterId,
  });

  final FieldType fieldType;
  final String filterId;

  @override
  Widget build(BuildContext context) {
    return switch (fieldType) {
      FieldType.RichText => TextFilterChoicechip(filterId: filterId),
      FieldType.Number => NumberFilterChoiceChip(filterId: filterId),
      FieldType.URL => URLFilterChoicechip(filterId: filterId),
      FieldType.Checkbox => CheckboxFilterChoicechip(filterId: filterId),
      FieldType.Checklist => ChecklistFilterChoicechip(filterId: filterId),
      FieldType.DateTime ||
      FieldType.LastEditedTime ||
      FieldType.CreatedTime =>
        DateFilterChoicechip(filterId: filterId),
      FieldType.SingleSelect ||
      FieldType.MultiSelect =>
        SelectOptionFilterChoicechip(filterId: filterId),
      // FieldType.Time =>
      //   TimeFilterChoiceChip(filterInfo: filterInfo),
      _ => const SizedBox.shrink(),
    };
  }
}
