import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/filter/time_filter_editor_bloc.dart';
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

class TimeFilterChoiceChip extends StatefulWidget {
  const TimeFilterChoiceChip({
    super.key,
    required this.filterInfo,
  });

  final FilterInfo filterInfo;

  @override
  State<TimeFilterChoiceChip> createState() => _TimeFilterChoiceChipState();
}

class _TimeFilterChoiceChipState extends State<TimeFilterChoiceChip> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimeFilterEditorBloc(
        filterInfo: widget.filterInfo,
      ),
      child: BlocBuilder<TimeFilterEditorBloc, TimeFilterEditorState>(
        builder: (context, state) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(200, 100)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (_) {
              return BlocProvider.value(
                value: context.read<TimeFilterEditorBloc>(),
                child: const TimeFilterEditor(),
              );
            },
            child: ChoiceChipButton(
              filterInfo: state.filterInfo,
            ),
          );
        },
      ),
    );
  }
}

class TimeFilterEditor extends StatefulWidget {
  const TimeFilterEditor({super.key});

  @override
  State<TimeFilterEditor> createState() => _TimeFilterEditorState();
}

class _TimeFilterEditorState extends State<TimeFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeFilterEditorBloc, TimeFilterEditorState>(
      builder: (context, state) {
        final List<Widget> children = [
          _buildFilterPanel(context, state),
          if (state.filter.condition != NumberFilterConditionPB.NumberIsEmpty &&
              state.filter.condition !=
                  NumberFilterConditionPB.NumberIsNotEmpty) ...[
            const VSpace(4),
            _buildFilterTimeField(context, state),
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
    BuildContext context,
    TimeFilterEditorState state,
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
            child: TimeFilterConditionPBList(
              filterInfo: state.filterInfo,
              popoverMutex: popoverMutex,
              onCondition: (condition) {
                context
                    .read<TimeFilterEditorBloc>()
                    .add(TimeFilterEditorEvent.updateCondition(condition));
              },
            ),
          ),
          const HSpace(4),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context
                      .read<TimeFilterEditorBloc>()
                      .add(const TimeFilterEditorEvent.delete());
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTimeField(
    BuildContext context,
    TimeFilterEditorState state,
  ) {
    return FlowyTextField(
      text: state.filter.content,
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      debounceDuration: const Duration(milliseconds: 300),
      autoFocus: false,
      onChanged: (text) {
        context
            .read<TimeFilterEditorBloc>()
            .add(TimeFilterEditorEvent.updateContent(text));
      },
    );
  }
}

class TimeFilterConditionPBList extends StatelessWidget {
  const TimeFilterConditionPBList({
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
    final timeFilter = filterInfo.timeFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: NumberFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              timeFilter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: timeFilter.condition.filterName,
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

extension TimeFilterConditionPBExtension on NumberFilterConditionPB {
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
