import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/database/card/row/cells/date_cell/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/date_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_option_editor.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateTypeOptionMobileWidgetBuilder extends TypeOptionWidgetBuilder {
  final DateTypeOptionMobileWidget _widget;
  DateTypeOptionMobileWidgetBuilder(
    DateTypeOptionContext typeOptionContext,
  ) : _widget = DateTypeOptionMobileWidget(
          typeOptionContext: typeOptionContext,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class DateTypeOptionMobileWidget extends TypeOptionWidget {
  const DateTypeOptionMobileWidget({
    super.key,
    required this.typeOptionContext,
  });

  final DateTypeOptionContext typeOptionContext;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DateTypeOptionBloc(typeOptionContext: typeOptionContext),
      child: BlocConsumer<DateTypeOptionBloc, DateTypeOptionState>(
        listener: (context, state) =>
            typeOptionContext.typeOption = state.typeOption,
        builder: (context, state) {
          final List<Widget> children = [
            PropertyEditContainer(
              child: DateFormatListTile(
                currentFormatStr: state.typeOption.dateFormat.title(),
                groupValue: context
                    .watch<DateTypeOptionBloc>()
                    .state
                    .typeOption
                    .dateFormat,
                onChanged: (newFormat) {
                  if (newFormat != null) {
                    context.read<DateTypeOptionBloc>().add(
                          DateTypeOptionEvent.didSelectDateFormat(
                            newFormat,
                          ),
                        );
                  }
                },
              ),
            ),
            PropertyEditContainer(
              child: TimeFormatListTile(
                currentFormatStr: state.typeOption.timeFormat.title(),
                groupValue: context
                    .watch<DateTypeOptionBloc>()
                    .state
                    .typeOption
                    .timeFormat,
                onChanged: (newFormat) {
                  if (newFormat != null) {
                    context.read<DateTypeOptionBloc>().add(
                          DateTypeOptionEvent.didSelectTimeFormat(
                            newFormat,
                          ),
                        );
                  }
                },
              ),
            ),
          ];

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, index) => const VSpace(8),
            itemCount: children.length,
            itemBuilder: (_, index) => children[index],
          );
        },
      ),
    );
  }
}
