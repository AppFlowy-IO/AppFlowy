import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';
import 'choicechip.dart';

class ChecklistFilterChoicechip extends StatelessWidget {
  const ChecklistFilterChoicechip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: PopoverController(),
      constraints: BoxConstraints.loose(const Size(200, 160)),
      direction: PopoverDirection.bottomWithCenterAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: ChecklistFilterEditor(filterId: filterId),
        );
      },
      child: SingleFilterBlocSelector<ChecklistFilter>(
        filterId: filterId,
        builder: (context, filter, field) {
          return ChoiceChipButton(
            fieldInfo: field,
            filterDesc: filter.getDescription(field),
          );
        },
      ),
    );
  }
}

class ChecklistFilterEditor extends StatefulWidget {
  const ChecklistFilterEditor({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  ChecklistState createState() => ChecklistState();
}

class ChecklistState extends State<ChecklistFilterEditor> {
  final PopoverMutex popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleFilterBlocSelector<ChecklistFilter>(
      filterId: widget.filterId,
      builder: (context, filter, field) {
        return SizedBox(
          height: 20,
          child: Row(
            children: [
              Expanded(
                child: FlowyText(
                  field.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const HSpace(4),
              ChecklistFilterConditionList(
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
                      context
                          .read<FilterEditorBloc>()
                          .add(FilterEditorEvent.deleteFilter(filter.filterId));
                      break;
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChecklistFilterConditionList extends StatelessWidget {
  const ChecklistFilterConditionList({
    super.key,
    required this.filter,
    required this.popoverMutex,
    required this.onCondition,
  });

  final ChecklistFilter filter;
  final PopoverMutex popoverMutex;
  final void Function(ChecklistFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithCenterAligned,
      mutex: popoverMutex,
      actions: ChecklistFilterConditionPB.values
          .map((action) => ConditionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filter.condition.filterName,
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
  ConditionWrapper(this.inner);

  final ChecklistFilterConditionPB inner;

  @override
  String get name => inner.filterName;
}

extension ChecklistFilterConditionPBExtension on ChecklistFilterConditionPB {
  String get filterName {
    switch (this) {
      case ChecklistFilterConditionPB.IsComplete:
        return LocaleKeys.grid_checklistFilter_isComplete.tr();
      case ChecklistFilterConditionPB.IsIncomplete:
        return LocaleKeys.grid_checklistFilter_isIncomplted.tr();
      default:
        return "";
    }
  }
}
