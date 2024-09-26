import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';

import 'choicechip.dart';

class CheckboxFilterChoicechip extends StatelessWidget {
  const CheckboxFilterChoicechip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(200, 76)),
      direction: PopoverDirection.bottomWithCenterAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: CheckboxFilterEditor(
            filterId: filterId,
          ),
        );
      },
      child: SingleFilterBlocSelector<CheckboxFilter>(
        filterId: filterId,
        builder: (context, filter, field) {
          return ChoiceChipButton(
            fieldInfo: field,
            filterDesc: filter.condition.filterName,
          );
        },
      ),
    );
  }
}

class CheckboxFilterEditor extends StatefulWidget {
  const CheckboxFilterEditor({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  State<CheckboxFilterEditor> createState() => _CheckboxFilterEditorState();
}

class _CheckboxFilterEditorState extends State<CheckboxFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleFilterBlocSelector<CheckboxFilter>(
      filterId: widget.filterId,
      builder: (context, filter, field) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: FlowyText(
                    field.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const HSpace(4),
                CheckboxFilterConditionList(
                  filter: filter,
                  popoverMutex: popoverMutex,
                  onCondition: (condition) {
                    final newFilter = filter.copyWith(condition: condition);
                    context
                        .read<FilterEditorBloc>()
                        .add(FilterEditorEvent.updateFilter(newFilter));
                  },
                ),
                DisclosureButton(
                  popoverMutex: popoverMutex,
                  onAction: (action) {
                    switch (action) {
                      case FilterDisclosureAction.delete:
                        context.read<FilterEditorBloc>().add(
                              FilterEditorEvent.deleteFilter(
                                filter.filterId,
                              ),
                            );
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CheckboxFilterConditionList extends StatelessWidget {
  const CheckboxFilterConditionList({
    super.key,
    required this.filter,
    required this.popoverMutex,
    required this.onCondition,
  });

  final CheckboxFilter filter;
  final PopoverMutex popoverMutex;
  final void Function(CheckboxFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: CheckboxFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              filter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filter.conditionName,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) {
        onCondition(action.inner);
        controller.close();
      },
    );
  }
}

class ConditionWrapper extends ActionCell {
  ConditionWrapper(this.inner, this.isSelected);

  final CheckboxFilterConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) =>
      isSelected ? const FlowySvg(FlowySvgs.check_s) : null;

  @override
  String get name => inner.filterName;
}

extension TextFilterConditionPBExtension on CheckboxFilterConditionPB {
  String get filterName {
    switch (this) {
      case CheckboxFilterConditionPB.IsChecked:
        return LocaleKeys.grid_checkboxFilter_isChecked.tr();
      case CheckboxFilterConditionPB.IsUnChecked:
        return LocaleKeys.grid_checkboxFilter_isUnchecked.tr();
      default:
        return "";
    }
  }
}
