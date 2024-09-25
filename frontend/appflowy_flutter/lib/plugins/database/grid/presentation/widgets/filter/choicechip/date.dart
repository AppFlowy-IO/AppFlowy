import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';

import 'choicechip.dart';

class DateFilterChoicechip extends StatelessWidget {
  const DateFilterChoicechip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(200, 120)),
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: DateFilterEditor(filterId: filterId),
        );
      },
      child: SingleFilterBlocSelector<DateTimeFilter>(
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

class DateFilterEditor extends StatefulWidget {
  const DateFilterEditor({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  State<DateFilterEditor> createState() => _DateFilterEditorState();
}

class _DateFilterEditorState extends State<DateFilterEditor> {
  final popoverMutex = PopoverMutex();
  final popooverController = PopoverController();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleFilterBlocSelector<DateTimeFilter>(
      filterId: widget.filterId,
      builder: (context, filter, field) {
        final List<Widget> children = [
          _buildFilterPanel(filter, field),
          if (filter.condition != DateFilterConditionPB.DateIsEmpty &&
              filter.condition != DateFilterConditionPB.DateIsNotEmpty) ...[
            const VSpace(4),
            _buildFilterContentField(filter),
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
    DateTimeFilter filter,
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
            child: DateFilterConditionList(
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

  Widget _buildFilterContentField(DateTimeFilter filter) {
    final isRange = filter.condition == DateFilterConditionPB.DateWithIn;
    String? text;

    if (isRange) {
      text =
          "${filter.start?.defaultFormat ?? ""} - ${filter.end?.defaultFormat ?? ""}";
      text = text == " - " ? null : text;
    } else {
      text = filter.timestamp.defaultFormat;
    }

    return AppFlowyPopover(
      controller: popooverController,
      triggerActions: PopoverTriggerFlags.none,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(260, 620)),
      offset: const Offset(0, 4),
      margin: EdgeInsets.zero,
      mutex: popoverMutex,
      child: FlowyButton(
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          borderRadius: Corners.s6Border,
        ),
        onTap: popooverController.show,
        text: FlowyText(
          text ?? "",
          overflow: TextOverflow.ellipsis,
        ),
      ),
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: SingleFilterBlocSelector<DateTimeFilter>(
            filterId: widget.filterId,
            builder: (context, filter, field) {
              return AppFlowyDatePicker(
                isRange: isRange,
                timeHintText: LocaleKeys.grid_field_selectTime.tr(),
                includeTime: false,
                dateFormat: DateFormatPB.Friendly,
                timeFormat: TimeFormatPB.TwentyFourHour,
                selectedDay: isRange ? filter.start : filter.timestamp,
                startDay: isRange ? filter.start : null,
                endDay: isRange ? filter.end : null,
                onDaySelected: (selectedDay, _) {
                  final newFilter = isRange
                      ? filter.copyWithRange(start: selectedDay, end: null)
                      : filter.copyWith(timestamp: selectedDay);
                  context
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.updateFilter(newFilter));
                  if (isRange) {
                    popooverController.close();
                  }
                },
                onRangeSelected: (start, end, _) {
                  final newFilter = filter.copyWithRange(
                    start: start,
                    end: end,
                  );
                  context
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.updateFilter(newFilter));
                },
                onIncludeTimeChanged: (_) {},
              );
            },
          ),
        );
      },
    );
  }
}

class DateFilterConditionList extends StatelessWidget {
  const DateFilterConditionList({
    super.key,
    required this.filter,
    required this.popoverMutex,
    required this.onCondition,
  });

  final DateTimeFilter filter;
  final PopoverMutex popoverMutex;
  final Function(DateFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: DateFilterConditionPB.values
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

  final DateFilterConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) =>
      isSelected ? const FlowySvg(FlowySvgs.check_s) : null;

  @override
  String get name => inner.filterName;
}

extension DateFilterConditionPBExtension on DateFilterConditionPB {
  String get filterName {
    return switch (this) {
      DateFilterConditionPB.DateIs => LocaleKeys.grid_dateFilter_is.tr(),
      DateFilterConditionPB.DateBefore =>
        LocaleKeys.grid_dateFilter_before.tr(),
      DateFilterConditionPB.DateAfter => LocaleKeys.grid_dateFilter_after.tr(),
      DateFilterConditionPB.DateOnOrBefore =>
        LocaleKeys.grid_dateFilter_onOrBefore.tr(),
      DateFilterConditionPB.DateOnOrAfter =>
        LocaleKeys.grid_dateFilter_onOrAfter.tr(),
      DateFilterConditionPB.DateWithIn =>
        LocaleKeys.grid_dateFilter_between.tr(),
      DateFilterConditionPB.DateIsEmpty =>
        LocaleKeys.grid_dateFilter_empty.tr(),
      DateFilterConditionPB.DateIsNotEmpty =>
        LocaleKeys.grid_dateFilter_notEmpty.tr(),
      _ => "",
    };
  }
}

extension DateTimeChoicechipExtension on DateTime {
  DateTime get considerLocal {
    return DateTime(year, month, day);
  }
}

extension DateTimeDefaultFormatExtension on DateTime? {
  String? get defaultFormat {
    return this != null ? DateFormat('dd/MM/yyyy').format(this!) : null;
  }
}
