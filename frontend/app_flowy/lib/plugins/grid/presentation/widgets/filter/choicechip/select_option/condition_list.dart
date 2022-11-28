import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/condition_button.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pb.dart';
import 'package:flutter/material.dart';

class SelectOptionFilterConditionList extends StatelessWidget {
  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(SelectOptionCondition) onCondition;
  const SelectOptionFilterConditionList({
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectOptionFilter = filterInfo.selectOptionFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: SelectOptionCondition.values
          .map(
            (action) => ConditionWrapper(
              action,
              selectOptionFilter.condition == action,
              filterInfo.field.fieldType,
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
    if (filterInfo.field.fieldType == FieldType.SingleSelect) {
      return filter.condition.singleSelectFilterName;
    } else {
      return filter.condition.multiSelectFilterName;
    }
  }
}

class ConditionWrapper extends ActionCell {
  final SelectOptionCondition inner;
  final bool isSelected;
  final FieldType fieldType;

  ConditionWrapper(this.inner, this.isSelected, this.fieldType);

  @override
  Widget? rightIcon(Color iconColor) {
    if (isSelected) {
      return svgWidget("grid/checkmark");
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

extension SelectOptionConditionExtension on SelectOptionCondition {
  String get singleSelectFilterName {
    switch (this) {
      case SelectOptionCondition.OptionIs:
        return LocaleKeys.grid_singleSelectOptionFilter_is.tr();
      case SelectOptionCondition.OptionIsEmpty:
        return LocaleKeys.grid_singleSelectOptionFilter_isEmpty.tr();
      case SelectOptionCondition.OptionIsNot:
        return LocaleKeys.grid_singleSelectOptionFilter_isNot.tr();
      case SelectOptionCondition.OptionIsNotEmpty:
        return LocaleKeys.grid_singleSelectOptionFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }

  String get multiSelectFilterName {
    switch (this) {
      case SelectOptionCondition.OptionIs:
        return LocaleKeys.grid_multiSelectOptionFilter_contains.tr();
      case SelectOptionCondition.OptionIsEmpty:
        return LocaleKeys.grid_multiSelectOptionFilter_isEmpty.tr();
      case SelectOptionCondition.OptionIsNot:
        return LocaleKeys.grid_multiSelectOptionFilter_doesNotContain.tr();
      case SelectOptionCondition.OptionIsNotEmpty:
        return LocaleKeys.grid_multiSelectOptionFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }
}
