import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter/material.dart';

import 'choicechip/checkbox.dart';
import 'choicechip/checklist/checklist.dart';
import 'choicechip/date.dart';
import 'choicechip/number.dart';
import 'choicechip/select_option/select_option.dart';
import 'choicechip/text.dart';
import 'choicechip/url.dart';
import 'filter_info.dart';

class FilterMenuItem extends StatelessWidget {
  final FilterInfo filterInfo;
  const FilterMenuItem({required this.filterInfo, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildFilterChoicechip(filterInfo);
  }
}

Widget buildFilterChoicechip(FilterInfo filterInfo) {
  switch (filterInfo.fieldInfo.fieldType) {
    case FieldType.Checkbox:
      return CheckboxFilterChoicechip(filterInfo: filterInfo);
    case FieldType.DateTime:
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return DateFilterChoicechip(filterInfo: filterInfo);
    case FieldType.MultiSelect:
      return SelectOptionFilterChoicechip(filterInfo: filterInfo);
    case FieldType.Number:
      return NumberFilterChoicechip(filterInfo: filterInfo);
    case FieldType.RichText:
      return TextFilterChoicechip(filterInfo: filterInfo);
    case FieldType.SingleSelect:
      return SelectOptionFilterChoicechip(filterInfo: filterInfo);
    case FieldType.URL:
      return URLFilterChoicechip(filterInfo: filterInfo);
    case FieldType.Checklist:
      return ChecklistFilterChoicechip(filterInfo: filterInfo);
    default:
      return const SizedBox();
  }
}
