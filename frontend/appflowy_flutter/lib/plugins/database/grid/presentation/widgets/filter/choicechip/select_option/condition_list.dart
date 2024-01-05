import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pb.dart';
import 'package:flutter/material.dart';

import '../../condition_button.dart';
import '../../filter_info.dart';

class SelectOptionFilterConditionList extends StatelessWidget {
  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(SelectOptionConditionPB) onCondition;
  const SelectOptionFilterConditionList({
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selectOptionFilter = filterInfo.selectOptionFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: SelectOptionConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              selectOptionFilter.condition == action,
              filterInfo.fieldInfo.fieldType,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filterName(selectOptionFilter),
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        onCondition(action.inner);
        controller.close();
      },
    );
  }

  String filterName(SelectOptionFilterPB filter) {
    if (filterInfo.fieldInfo.fieldType == FieldType.SingleSelect) {
      return filter.condition.singleSelectFilterName;
    } else {
      return filter.condition.multiSelectFilterName;
    }
  }
}

class ConditionWrapper extends ActionCell {
  final SelectOptionConditionPB inner;
  final bool isSelected;
  final FieldType fieldType;

  ConditionWrapper(this.inner, this.isSelected, this.fieldType);

  @override
  Widget? rightIcon(Color iconColor) {
    if (isSelected) {
      return const FlowySvg(FlowySvgs.check_s);
    } else {
      return null;
    }
  }

  @override
  String get name {
    if (fieldType == FieldType.SingleSelect) {
      return inner.singleSelectFilterName;
    } else {
      return inner.multiSelectFilterName;
    }
  }
}

extension SelectOptionConditionPBExtension on SelectOptionConditionPB {
  String get singleSelectFilterName {
    switch (this) {
      case SelectOptionConditionPB.OptionIs:
        return LocaleKeys.grid_singleSelectOptionFilter_is.tr();
      case SelectOptionConditionPB.OptionIsEmpty:
        return LocaleKeys.grid_singleSelectOptionFilter_isEmpty.tr();
      case SelectOptionConditionPB.OptionIsNot:
        return LocaleKeys.grid_singleSelectOptionFilter_isNot.tr();
      case SelectOptionConditionPB.OptionIsNotEmpty:
        return LocaleKeys.grid_singleSelectOptionFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }

  String get multiSelectFilterName {
    switch (this) {
      case SelectOptionConditionPB.OptionIs:
        return LocaleKeys.grid_multiSelectOptionFilter_contains.tr();
      case SelectOptionConditionPB.OptionIsEmpty:
        return LocaleKeys.grid_multiSelectOptionFilter_isEmpty.tr();
      case SelectOptionConditionPB.OptionIsNot:
        return LocaleKeys.grid_multiSelectOptionFilter_doesNotContain.tr();
      case SelectOptionConditionPB.OptionIsNotEmpty:
        return LocaleKeys.grid_multiSelectOptionFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }
}
