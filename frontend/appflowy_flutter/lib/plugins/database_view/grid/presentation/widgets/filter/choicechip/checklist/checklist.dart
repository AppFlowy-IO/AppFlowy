import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/application/filter/checklist_filter_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../condition_button.dart';
import '../../disclosure_button.dart';
import '../../filter_info.dart';
import '../choicechip.dart';

class ChecklistFilterChoicechip extends StatefulWidget {
  final FilterInfo filterInfo;
  const ChecklistFilterChoicechip({required this.filterInfo, Key? key})
      : super(key: key);

  @override
  State<ChecklistFilterChoicechip> createState() =>
      _ChecklistFilterChoicechipState();
}

class _ChecklistFilterChoicechipState extends State<ChecklistFilterChoicechip> {
  late ChecklistFilterEditorBloc bloc;
  late PopoverMutex popoverMutex;

  @override
  void initState() {
    popoverMutex = PopoverMutex();
    bloc = ChecklistFilterEditorBloc(filterInfo: widget.filterInfo);
    bloc.add(const ChecklistFilterEditorEvent.initial());
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ChecklistFilterEditorBloc, ChecklistFilterEditorState>(
        builder: (blocContext, state) {
          return AppFlowyPopover(
            controller: PopoverController(),
            constraints: BoxConstraints.loose(const Size(200, 160)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (BuildContext context) {
              return ChecklistFilterEditor(
                bloc: bloc,
                popoverMutex: popoverMutex,
              );
            },
            child: ChoiceChipButton(
              filterInfo: widget.filterInfo,
              filterDesc: state.filterDesc,
            ),
          );
        },
      ),
    );
  }
}

class ChecklistFilterEditor extends StatefulWidget {
  final ChecklistFilterEditorBloc bloc;
  final PopoverMutex popoverMutex;
  const ChecklistFilterEditor({
    required this.bloc,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  ChecklistState createState() => ChecklistState();
}

class ChecklistState extends State<ChecklistFilterEditor> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<ChecklistFilterEditorBloc, ChecklistFilterEditorState>(
        builder: (context, state) {
          return SizedBox(
            height: 20,
            child: Row(
              children: [
                FlowyText(state.filterInfo.fieldInfo.name),
                const HSpace(4),
                ChecklistFilterConditionList(
                  filterInfo: state.filterInfo,
                ),
                const Spacer(),
                DisclosureButton(
                  popoverMutex: widget.popoverMutex,
                  onAction: (action) {
                    switch (action) {
                      case FilterDisclosureAction.delete:
                        context
                            .read<ChecklistFilterEditorBloc>()
                            .add(const ChecklistFilterEditorEvent.delete());
                        break;
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChecklistFilterConditionList extends StatelessWidget {
  final FilterInfo filterInfo;
  const ChecklistFilterConditionList({
    required this.filterInfo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checklistFilter = filterInfo.checklistFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: ChecklistFilterConditionPB.values
          .map((action) => ConditionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: checklistFilter.condition.filterName,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        context
            .read<ChecklistFilterEditorBloc>()
            .add(ChecklistFilterEditorEvent.updateCondition(action.inner));
        controller.close();
      },
    );
  }
}

class ConditionWrapper extends ActionCell {
  final ChecklistFilterConditionPB inner;

  ConditionWrapper(this.inner);

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
