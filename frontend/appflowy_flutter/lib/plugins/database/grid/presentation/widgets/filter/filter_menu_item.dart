import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'choicechip/checkbox.dart';
import 'choicechip/checklist.dart';
// import 'choicechip/date.dart';
import 'choicechip/number.dart';
import 'choicechip/select_option/select_option.dart';
import 'choicechip/text.dart';
import 'choicechip/url.dart';
import 'filter_info.dart';

class FilterMenuItem extends StatelessWidget {
  const FilterMenuItem({
    super.key,
    required this.fieldController,
    required this.filterId,
  });

  final FieldController fieldController;
  final String filterId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FilterEditorBloc, FilterEditorState, FilterInfo?>(
      selector: (state) => state.filters
          .firstWhereOrNull((filter) => filter.filterId == filterId),
      builder: (context, filterInfo) {
        if (filterInfo == null) {
          return const SizedBox.shrink();
        }
        return switch (filterInfo.fieldInfo.fieldType) {
          FieldType.RichText => TextFilterChoicechip(
              fieldController: fieldController,
              filterInfo: filterInfo,
            ),
          FieldType.Number => NumberFilterChoiceChip(
              fieldController: fieldController,
              filterInfo: filterInfo,
            ),
          FieldType.URL => URLFilterChoiceChip(
              fieldController: fieldController,
              filterInfo: filterInfo,
            ),
          FieldType.Checkbox => CheckboxFilterChoicechip(
              fieldController: fieldController,
              filterInfo: filterInfo,
            ),
          FieldType.Checklist => ChecklistFilterChoicechip(
              fieldController: fieldController,
              filterInfo: filterInfo,
            ),
          // FieldType.DateTime => DateFilterChoicechip(filterInfo: filterInfo),
          FieldType.SingleSelect ||
          FieldType.MultiSelect =>
            SelectOptionFilterChoicechip(
              fieldController: fieldController,
              filterInfo: filterInfo,
            ),
          // FieldType.Time =>
          //   TimeFilterChoiceChip(filterInfo: filterInfo),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
