import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';

import 'choicechip.dart';

class TimeFilterChoiceChip extends StatelessWidget {
  const TimeFilterChoiceChip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(200, 100)),
      direction: PopoverDirection.bottomWithCenterAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: TimeFilterEditor(filterId: filterId),
        );
      },
      child: SingleFilterBlocSelector<TimeFilter>(
        filterId: filterId,
        builder: (context, filter, field) {
          return ChoiceChipButton(
            fieldInfo: field,
          );
        },
      ),
    );
  }
}

class TimeFilterEditor extends StatefulWidget {
  const TimeFilterEditor({
    super.key,
    required this.filterId,
  });

  final String filterId;
  @override
  State<TimeFilterEditor> createState() => _TimeFilterEditorState();
}

class _TimeFilterEditorState extends State<TimeFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleFilterBlocSelector<TimeFilter>(
      filterId: widget.filterId,
      builder: (context, filter, field) {
        final List<Widget> children = [
          _buildFilterPanel(filter, field),
          if (filter.condition != NumberFilterConditionPB.NumberIsEmpty &&
              filter.condition != NumberFilterConditionPB.NumberIsNotEmpty) ...[
            const VSpace(4),
            _buildFilterTimeField(filter, field),
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
    TimeFilter filter,
    FieldInfo field,
  ) {
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
          Expanded(
            child: TimeFilterConditionList(
              filter: filter,
              popoverMutex: popoverMutex,
              onCondition: (condition) {
                final newFilter = filter.copyWith(condition: condition);
                context
                    .read<FilterEditorBloc>()
                    .add(FilterEditorEvent.updateFilter(newFilter));
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
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.deleteFilter(filter.filterId));
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTimeField(
    TimeFilter filter,
    FieldInfo field,
  ) {
    return FlowyTextField(
      text: filter.content,
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      debounceDuration: const Duration(milliseconds: 300),
      autoFocus: false,
      onChanged: (text) {
        final newFilter = filter.copyWith(content: text);
        context
            .read<FilterEditorBloc>()
            .add(FilterEditorEvent.updateFilter(newFilter));
      },
    );
  }
}

class TimeFilterConditionList extends StatelessWidget {
  const TimeFilterConditionList({
    super.key,
    required this.filter,
    required this.popoverMutex,
    required this.onCondition,
  });

  final TimeFilter filter;
  final PopoverMutex popoverMutex;
  final void Function(NumberFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: NumberFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              filter.condition == action,
            ),
          )
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
