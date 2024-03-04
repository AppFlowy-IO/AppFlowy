import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/condition_button.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class SelectOptionFilterConditionList extends StatelessWidget {
  const SelectOptionFilterConditionList({
    super.key,
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
  });

  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(SelectOptionConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    final selectOptionFilter = filterInfo.selectOptionFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: _conditionsForFieldType(filterInfo.fieldInfo.fieldType)
          .map(
            (action) => ConditionWrapper(
              action,
              selectOptionFilter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: selectOptionFilter.condition.i18n,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        onCondition(action.inner);
        controller.close();
      },
    );
  }

  List<SelectOptionConditionPB> _conditionsForFieldType(FieldType fieldType) {
    // SelectOptionConditionPB.values is not in order
    return switch (fieldType) {
      FieldType.SingleSelect => [
          SelectOptionConditionPB.OptionIs,
          SelectOptionConditionPB.OptionIsNot,
          SelectOptionConditionPB.OptionIsEmpty,
          SelectOptionConditionPB.OptionIsNotEmpty,
        ],
      FieldType.MultiSelect => [
          SelectOptionConditionPB.OptionContains,
          SelectOptionConditionPB.OptionDoesNotContain,
          SelectOptionConditionPB.OptionIs,
          SelectOptionConditionPB.OptionIsNot,
          SelectOptionConditionPB.OptionIsEmpty,
          SelectOptionConditionPB.OptionIsNotEmpty,
        ],
      _ => [],
    };
  }
}

class ConditionWrapper extends ActionCell {
  ConditionWrapper(this.inner, this.isSelected);

  final SelectOptionConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) {
    return isSelected ? const FlowySvg(FlowySvgs.check_s) : null;
  }

  @override
  String get name => inner.i18n;
}

extension SelectOptionConditionPBExtension on SelectOptionConditionPB {
  String get i18n {
    return switch (this) {
      SelectOptionConditionPB.OptionIs =>
        LocaleKeys.grid_selectOptionFilter_is.tr(),
      SelectOptionConditionPB.OptionIsNot =>
        LocaleKeys.grid_selectOptionFilter_isNot.tr(),
      SelectOptionConditionPB.OptionContains =>
        LocaleKeys.grid_selectOptionFilter_isNot.tr(),
      SelectOptionConditionPB.OptionDoesNotContain =>
        LocaleKeys.grid_selectOptionFilter_isNot.tr(),
      SelectOptionConditionPB.OptionIsEmpty =>
        LocaleKeys.grid_selectOptionFilter_isEmpty.tr(),
      SelectOptionConditionPB.OptionIsNotEmpty =>
        LocaleKeys.grid_selectOptionFilter_isNotEmpty.tr(),
      _ => "",
    };
  }
}
