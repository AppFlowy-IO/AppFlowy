import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/condition_button.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class SelectOptionFilterConditionList extends StatelessWidget {
  const SelectOptionFilterConditionList({
    super.key,
    required this.filter,
    required this.fieldType,
    required this.popoverMutex,
    required this.onCondition,
  });

  final SelectOptionFilter filter;
  final FieldType fieldType;
  final PopoverMutex popoverMutex;
  final void Function(SelectOptionFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: _conditionsForFieldType(fieldType)
          .map(
            (action) => ConditionWrapper(
              action,
              filter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filter.condition.i18n,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        onCondition(action.inner);
        controller.close();
      },
    );
  }

  List<SelectOptionFilterConditionPB> _conditionsForFieldType(
    FieldType fieldType,
  ) {
    // SelectOptionFilterConditionPB.values is not in order
    return switch (fieldType) {
      FieldType.SingleSelect => [
          SelectOptionFilterConditionPB.OptionIs,
          SelectOptionFilterConditionPB.OptionIsNot,
          SelectOptionFilterConditionPB.OptionIsEmpty,
          SelectOptionFilterConditionPB.OptionIsNotEmpty,
        ],
      FieldType.MultiSelect => [
          SelectOptionFilterConditionPB.OptionContains,
          SelectOptionFilterConditionPB.OptionDoesNotContain,
          SelectOptionFilterConditionPB.OptionIs,
          SelectOptionFilterConditionPB.OptionIsNot,
          SelectOptionFilterConditionPB.OptionIsEmpty,
          SelectOptionFilterConditionPB.OptionIsNotEmpty,
        ],
      _ => [],
    };
  }
}

class ConditionWrapper extends ActionCell {
  ConditionWrapper(this.inner, this.isSelected);

  final SelectOptionFilterConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) {
    return isSelected ? const FlowySvg(FlowySvgs.check_s) : null;
  }

  @override
  String get name => inner.i18n;
}

extension SelectOptionFilterConditionPBExtension
    on SelectOptionFilterConditionPB {
  String get i18n {
    return switch (this) {
      SelectOptionFilterConditionPB.OptionIs =>
        LocaleKeys.grid_selectOptionFilter_is.tr(),
      SelectOptionFilterConditionPB.OptionIsNot =>
        LocaleKeys.grid_selectOptionFilter_isNot.tr(),
      SelectOptionFilterConditionPB.OptionContains =>
        LocaleKeys.grid_selectOptionFilter_contains.tr(),
      SelectOptionFilterConditionPB.OptionDoesNotContain =>
        LocaleKeys.grid_selectOptionFilter_doesNotContain.tr(),
      SelectOptionFilterConditionPB.OptionIsEmpty =>
        LocaleKeys.grid_selectOptionFilter_isEmpty.tr(),
      SelectOptionFilterConditionPB.OptionIsNotEmpty =>
        LocaleKeys.grid_selectOptionFilter_isNotEmpty.tr(),
      _ => "",
    };
  }
}
