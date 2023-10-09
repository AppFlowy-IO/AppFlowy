import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/timestamp_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'date.dart';

class TimestampTypeOptionEditor extends StatelessWidget {
  final TimestampTypeOptionParser parser;
  final PopoverMutex popoverMutex;

  const TimestampTypeOptionEditor({
    required this.parser,
    required this.popoverMutex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TimestampTypeOptionBloc(typeOptionContext: typeOptionContext),
      child: BlocConsumer<TimestampTypeOptionBloc, TimestampTypeOptionState>(
        listener: (context, state) =>
            typeOptionContext.typeOption = state.typeOption,
        builder: (context, state) {
          final List<Widget> children = [
            const TypeOptionSeparator(),
            _renderDateFormatButton(context, state.typeOption.dateFormat),
            _renderTimeFormatButton(context, state.typeOption.timeFormat),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: IncludeTimeButton(
                onChanged: (value) => context
                    .read<TimestampTypeOptionBloc>()
                    .add(TimestampTypeOptionEvent.includeTime(!value)),
                value: state.typeOption.includeTime,
              ),
            ),
          ];

          return ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              if (index == 0) {
                return const SizedBox();
              } else {
                return VSpace(GridSize.typeOptionSeparatorHeight);
              }
            },
            itemCount: children.length,
            itemBuilder: (BuildContext context, int index) => children[index],
          );
        },
      ),
    );
  }

  Widget _renderDateFormatButton(
    BuildContext context,
    DateFormatPB dataFormat,
  ) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (popoverContext) {
        return DateFormatList(
          selectedFormat: dataFormat,
          onSelected: (format) {
            context
                .read<TimestampTypeOptionBloc>()
                .add(TimestampTypeOptionEvent.didSelectDateFormat(format));
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: DateFormatButton(),
      ),
    );
  }

  Widget _renderTimeFormatButton(
    BuildContext context,
    TimeFormatPB timeFormat,
  ) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (BuildContext popoverContext) {
        return TimeFormatList(
          selectedFormat: timeFormat,
          onSelected: (format) {
            context
                .read<TimestampTypeOptionBloc>()
                .add(TimestampTypeOptionEvent.didSelectTimeFormat(format));
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TimeFormatButton(timeFormat: timeFormat),
      ),
    );
  }
}

class IncludeTimeButton extends StatelessWidget {
  final bool value;
  final Function(bool value) onChanged;
  const IncludeTimeButton({
    super.key,
    required this.onChanged,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: Padding(
        padding: GridSize.typeOptionContentInsets,
        child: Row(
          children: [
            FlowySvg(
              FlowySvgs.clock_alarm_s,
              color: Theme.of(context).iconTheme.color,
            ),
            const HSpace(6),
            FlowyText.medium(LocaleKeys.grid_field_includeTime.tr()),
            const Spacer(),
            Toggle(
              value: value,
              onChanged: onChanged,
              style: ToggleStyle.big,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
