import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/filter/number_filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';
import '../filter_info.dart';

import 'choicechip.dart';

class NumberFilterChoiceChip extends StatelessWidget {
  const NumberFilterChoiceChip({
    super.key,
    required this.fieldController,
    required this.filterInfo,
  });

  final FieldController fieldController;
  final FilterInfo filterInfo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NumberFilterBloc(
        fieldController: fieldController,
        filterInfo: filterInfo,
      ),
      child: Builder(
        builder: (context) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(200, 100)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<NumberFilterBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<FilterEditorBloc>(),
                  ),
                ],
                child: const NumberFilterEditor(),
              );
            },
            child: BlocBuilder<NumberFilterBloc, NumberFilterState>(
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

  String _makeFilterDesc(NumberFilterState state) {
    final condition = state.filter.condition;

    if (condition == NumberFilterConditionPB.NumberIsEmpty ||
        condition == NumberFilterConditionPB.NumberIsNotEmpty) {
      return condition.shortName;
    }

    return "${condition.shortName} ${state.filter.content}";
  }
}

class NumberFilterEditor extends StatefulWidget {
  const NumberFilterEditor({super.key});

  @override
  State<NumberFilterEditor> createState() => _NumberFilterEditorState();
}

class _NumberFilterEditorState extends State<NumberFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NumberFilterBloc, NumberFilterState>(
      builder: (context, state) {
        final List<Widget> children = [
          _buildFilterPanel(state),
          if (state.filter.condition != NumberFilterConditionPB.NumberIsEmpty &&
              state.filter.condition !=
                  NumberFilterConditionPB.NumberIsNotEmpty) ...[
            const VSpace(4),
            _buildFilterNumberField(context, state),
          ],
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: IntrinsicHeight(child: Column(children: children)),
        );
      },
    );
  }

  Widget _buildFilterPanel(
    NumberFilterState state,
  ) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              state.filterInfo.fieldInfo.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(4),
          Expanded(
            child: NumberFilterConditionPBList(
              filterInfo: state.filterInfo,
              popoverMutex: popoverMutex,
              onCondition: (condition) {
                context
                    .read<NumberFilterBloc>()
                    .add(NumberFilterEvent.updateCondition(condition));
              },
            ),
          ),
          const HSpace(4),
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
  }

  Widget _buildFilterNumberField(
    BuildContext context,
    NumberFilterState state,
  ) {
    return FlowyTextField(
      text: state.filter.content,
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      debounceDuration: const Duration(milliseconds: 300),
      autoFocus: false,
      onChanged: (text) {
        context
            .read<NumberFilterBloc>()
            .add(NumberFilterEvent.updateContent(text));
      },
    );
  }
}

class NumberFilterConditionPBList extends StatelessWidget {
  const NumberFilterConditionPBList({
    super.key,
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
  });

  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(NumberFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    final numberFilter = filterInfo.numberFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: NumberFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              numberFilter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: numberFilter.condition.filterName,
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

  final NumberFilterConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) =>
      isSelected ? const FlowySvg(FlowySvgs.check_s) : null;

  @override
  String get name => inner.filterName;
}

extension NumberFilterConditionPBExtension on NumberFilterConditionPB {
  String get shortName {
    return switch (this) {
      NumberFilterConditionPB.Equal => "=",
      NumberFilterConditionPB.NotEqual => "≠",
      NumberFilterConditionPB.LessThan => "<",
      NumberFilterConditionPB.LessThanOrEqualTo => "≤",
      NumberFilterConditionPB.GreaterThan => ">",
      NumberFilterConditionPB.GreaterThanOrEqualTo => "≥",
      NumberFilterConditionPB.NumberIsEmpty =>
        LocaleKeys.grid_numberFilter_isEmpty.tr(),
      NumberFilterConditionPB.NumberIsNotEmpty =>
        LocaleKeys.grid_numberFilter_isNotEmpty.tr(),
      _ => "",
    };
  }

  String get filterName {
    return switch (this) {
      NumberFilterConditionPB.Equal => LocaleKeys.grid_numberFilter_equal.tr(),
      NumberFilterConditionPB.NotEqual =>
        LocaleKeys.grid_numberFilter_notEqual.tr(),
      NumberFilterConditionPB.LessThan =>
        LocaleKeys.grid_numberFilter_lessThan.tr(),
      NumberFilterConditionPB.LessThanOrEqualTo =>
        LocaleKeys.grid_numberFilter_lessThanOrEqualTo.tr(),
      NumberFilterConditionPB.GreaterThan =>
        LocaleKeys.grid_numberFilter_greaterThan.tr(),
      NumberFilterConditionPB.GreaterThanOrEqualTo =>
        LocaleKeys.grid_numberFilter_greaterThanOrEqualTo.tr(),
      NumberFilterConditionPB.NumberIsEmpty =>
        LocaleKeys.grid_numberFilter_isEmpty.tr(),
      NumberFilterConditionPB.NumberIsNotEmpty =>
        LocaleKeys.grid_numberFilter_isNotEmpty.tr(),
      _ => "",
    };
  }
}
