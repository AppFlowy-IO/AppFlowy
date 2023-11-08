import 'package:appflowy/mobile/presentation/database/card/row/cells/date_cell/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/timestamp_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_option_editor.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimestampTypeOptionMobileWidgetBuilder extends TypeOptionWidgetBuilder {
  final TimestampTypeOptionMobileWidget _widget;

  TimestampTypeOptionMobileWidgetBuilder(
    TimestampTypeOptionContext typeOptionContext,
  ) : _widget = TimestampTypeOptionMobileWidget(
          typeOptionContext: typeOptionContext,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class TimestampTypeOptionMobileWidget extends TypeOptionWidget {
  final TimestampTypeOptionContext typeOptionContext;

  const TimestampTypeOptionMobileWidget({
    required this.typeOptionContext,
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
            // used to add a separator padding at the top
            const SizedBox.shrink(),
            DateFormatListTile(
              currentFormatStr: state.typeOption.dateFormat.title(),
              groupValue: context
                  .watch<TimestampTypeOptionBloc>()
                  .state
                  .typeOption
                  .dateFormat,
              onChanged: (newFormat) {
                if (newFormat != null) {
                  context.read<TimestampTypeOptionBloc>().add(
                        TimestampTypeOptionEvent.didSelectDateFormat(
                          newFormat,
                        ),
                      );
                }
              },
            ),
            IncludeTimeSwitch(
              switchValue: state.typeOption.includeTime,
              onChanged: (value) => context
                  .read<TimestampTypeOptionBloc>()
                  .add(TimestampTypeOptionEvent.includeTime(value)),
            ),
            if (state.typeOption.includeTime)
              TimeFormatListTile(
                currentFormatStr: state.typeOption.timeFormat.title(),
                groupValue: context
                    .watch<TimestampTypeOptionBloc>()
                    .state
                    .typeOption
                    .timeFormat,
                onChanged: (newFormat) {
                  if (newFormat != null) {
                    context.read<TimestampTypeOptionBloc>().add(
                          TimestampTypeOptionEvent.didSelectTimeFormat(
                            newFormat,
                          ),
                        );
                  }
                },
              ),
          ];

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const VSpace(8),
            itemCount: children.length,
            itemBuilder: (BuildContext context, int index) => children[index],
          );
        },
      ),
    );
  }
}
