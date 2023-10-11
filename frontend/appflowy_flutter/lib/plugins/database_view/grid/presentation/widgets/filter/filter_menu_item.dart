import 'package:appflowy/plugins/database_view/application/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter/material.dart';

import 'choicechip/checkbox.dart';
import 'choicechip/checklist/checklist.dart';
import 'choicechip/date.dart';
import 'choicechip/number.dart';
import 'choicechip/select_option/select_option.dart';
import 'choicechip/text.dart';
import 'choicechip/url.dart';

class FilterMenuItem extends StatelessWidget {
  final String viewId;
  final FilterInfo filterInfo;
  const FilterMenuItem({
    required this.viewId,
    required this.filterInfo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return switch (filterInfo.field.fieldType) {
      FieldType.Checkbox =>
        CheckboxFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      FieldType.DateTime ||
      FieldType.LastEditedTime ||
      FieldType.CreatedTime =>
        DateFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      FieldType.MultiSelect =>
        SelectOptionFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      FieldType.Number =>
        NumberFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      FieldType.RichText =>
        TextFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      FieldType.SingleSelect =>
        SelectOptionFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      FieldType.URL =>
        URLFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      FieldType.Checklist =>
        ChecklistFilterChoicechip(viewId: viewId, filterInfo: filterInfo),
      _ => const SizedBox(),
    };
  }
}
