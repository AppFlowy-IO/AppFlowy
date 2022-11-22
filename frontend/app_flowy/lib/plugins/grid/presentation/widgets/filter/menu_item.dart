import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:flutter/material.dart';

import 'choicechip/checkbox.dart';
import 'choicechip/date.dart';
import 'choicechip/number.dart';
import 'choicechip/select_option.dart';
import 'choicechip/text.dart';
import 'choicechip/url.dart';

class FilterMenuItem extends StatelessWidget {
  final FilterPB filter;
  const FilterMenuItem({required this.filter, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildFilterChoicechip(filter);
  }
}

Widget buildFilterChoicechip(FilterPB filter) {
  switch (filter.fieldType) {
    case FieldType.Checkbox:
      return CheckboxFilterChoicechip(filter: filter);
    case FieldType.DateTime:
      return DateFilterChoicechip(filter: filter);
    case FieldType.MultiSelect:
      return SelectOptionFilterChoicechip(filter: filter);
    case FieldType.Number:
      return NumberFilterChoicechip(filter: filter);
    case FieldType.RichText:
      return TextFilterChoicechip(filter: filter);
    case FieldType.SingleSelect:
      return SelectOptionFilterChoicechip(filter: filter);
    case FieldType.URL:
      return URLFilterChoicechip(filter: filter);
    default:
      return const SizedBox();
  }
}
