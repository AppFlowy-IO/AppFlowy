import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/filter/checklist_filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';
import '../filter_info.dart';
import 'choicechip.dart';

class ChecklistFilterChoicechip extends StatelessWidget {
  const ChecklistFilterChoicechip({required this.filterInfo, super.key});

  final FilterInfo filterInfo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChecklistFilterBloc(
        filterInfo: filterInfo,
      ),
      child: Builder(
        builder: (context) {
          return AppFlowyPopover(
            controller: PopoverController(),
            constraints: BoxConstraints.loose(const Size(200, 160)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<ChecklistFilterBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<FilterEditorBloc>(),
                  ),
                ],
                child: const ChecklistFilterEditor(),
              );
            },
            child: BlocBuilder<ChecklistFilterBloc, ChecklistFilterState>(
              builder: (context, state) {
                return ChoiceChipButton(
                  filterInfo: state.filterInfo,
                  filterDesc: _makeFilterDesc(state),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _makeFilterDesc(ChecklistFilterState state) {
    return state.filter.condition.filterName;
  }
}

class ChecklistFilterEditor extends StatefulWidget {
  const ChecklistFilterEditor({
    super.key,
  });

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
    return BlocBuilder<ChecklistFilterBloc, ChecklistFilterState>(
      builder: (context, state) {
        return SizedBox(
          height: 20,
          child: Row(
            children: [
              Expanded(
                child: FlowyText(
                  state.filterInfo.fieldInfo.field.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const HSpace(4),
              ChecklistFilterConditionList(
                filterInfo: state.filterInfo,
                popoverMutex: popoverMutex,
              ),
              DisclosureButton(
                popoverMutex: popoverMutex,
                onAction: (action) {
                  switch (action) {
                    case FilterDisclosureAction.delete:
                      context.read<FilterEditorBloc>().add(
                            FilterEditorEvent.deleteFilter(
                              state.filterInfo.filterId,
                            ),
                          );
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
    required this.filterInfo,
    required this.popoverMutex,
  });

  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    final checklistFilter = filterInfo.checklistFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithCenterAligned,
      mutex: popoverMutex,
      actions: ChecklistFilterConditionPB.values
          .map((action) => ConditionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: checklistFilter.condition.filterName,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) {
        context
            .read<ChecklistFilterBloc>()
            .add(ChecklistFilterEvent.updateCondition(action.inner));
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
