import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/filter/checkbox_filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';
import '../filter_info.dart';

import 'choicechip.dart';

class CheckboxFilterChoicechip extends StatelessWidget {
  const CheckboxFilterChoicechip({
    super.key,
    required this.filterInfo,
  });

  final FilterInfo filterInfo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckboxFilterBloc(
        filterInfo: filterInfo,
      ),
      child: Builder(
        builder: (context) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(200, 76)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<CheckboxFilterBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<FilterEditorBloc>(),
                  ),
                ],
                child: const CheckboxFilterEditor(),
              );
            },
            child: BlocBuilder<CheckboxFilterBloc, CheckboxFilterState>(
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

  String _makeFilterDesc(CheckboxFilterState state) {
    return state.filter.condition.filterName;
  }
}

class CheckboxFilterEditor extends StatefulWidget {
  const CheckboxFilterEditor({super.key});

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
    return BlocBuilder<CheckboxFilterBloc, CheckboxFilterState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: FlowyText(
                    state.filterInfo.fieldInfo.field.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const HSpace(4),
                CheckboxFilterConditionList(
                  filterInfo: state.filterInfo,
                  popoverMutex: popoverMutex,
                  onCondition: (condition) {
                    context
                        .read<CheckboxFilterBloc>()
                        .add(CheckboxFilterEvent.updateCondition(condition));
                  },
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
          ),
        );
      },
    );
  }
}

class CheckboxFilterConditionList extends StatelessWidget {
  const CheckboxFilterConditionList({
    super.key,
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
  });

  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(CheckboxFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    final checkboxFilter = filterInfo.checkboxFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: CheckboxFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              checkboxFilter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: checkboxFilter.condition.filterName,
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
