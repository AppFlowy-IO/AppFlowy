import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database_view/application/field/type_option/timestamp_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_option_editor.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/include_time_button.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'builder.dart';
import 'date.dart';

class TimestampTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  TimestampTypeOptionWidgetBuilder(
    TimestampTypeOptionContext typeOptionContext,
    PopoverMutex popoverMutex,
  ) : _widget = TimestampTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          popoverMutex: popoverMutex,
        );

  final TimestampTypeOptionWidget _widget;

  @override
  Widget? build(BuildContext context) => _widget;
}

class TimestampTypeOptionWidget extends TypeOptionWidget {
  const TimestampTypeOptionWidget({
    super.key,
    required this.typeOptionContext,
    required this.popoverMutex,
  });

  final TimestampTypeOptionContext typeOptionContext;
  final PopoverMutex popoverMutex;

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
                return const SizedBox.shrink();
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
      popupBuilder: (popoverContext) => DateFormatList(
        selectedFormat: dataFormat,
        onSelected: (format) {
          context
              .read<TimestampTypeOptionBloc>()
              .add(TimestampTypeOptionEvent.didSelectDateFormat(format));
          PopoverContainer.of(popoverContext).close();
        },
      ),
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
      popupBuilder: (BuildContext popoverContext) => TimeFormatList(
        selectedFormat: timeFormat,
        onSelected: (format) {
          context
              .read<TimestampTypeOptionBloc>()
              .add(TimestampTypeOptionEvent.didSelectTimeFormat(format));
          PopoverContainer.of(popoverContext).close();
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TimeFormatButton(timeFormat: timeFormat),
      ),
    );
  }
}
