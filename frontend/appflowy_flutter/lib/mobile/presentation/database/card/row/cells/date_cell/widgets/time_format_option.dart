import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cal_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TimeFormatOption extends StatelessWidget {
  const TimeFormatOption({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return Row(
      children: [
        Text(
          LocaleKeys.grid_field_timeFormat.tr(),
          style: style.textTheme.titleMedium,
        ),
        const Spacer(),
        BlocSelector<DateCellCalendarBloc, DateCellCalendarState, TimeFormatPB>(
          selector: (state) => state.dateTypeOptionPB.timeFormat,
          builder: (context, state) {
            return GestureDetector(
              child: Row(
                children: [
                  Text(
                    state.title(),
                    style: style.textTheme.titleMedium,
                  ),
                  const HSpace(4),
                  Icon(
                    Icons.arrow_forward_ios_sharp,
                    color: style.hintColor,
                  ),
                ],
              ),
              onTap: () => showFlowyMobileBottomSheet(
                context,
                title: LocaleKeys.grid_field_timeFormat.tr(),
                builder: (_) {
                  return BlocProvider.value(
                    value: context.read<DateCellCalendarBloc>(),
                    child: Column(
                      children: [
                        _TimeFormatRadioListTile(
                          title:
                              LocaleKeys.grid_field_timeFormatTwelveHour.tr(),
                          timeFormatPB: TimeFormatPB.TwelveHour,
                        ),
                        _TimeFormatRadioListTile(
                          title: LocaleKeys.grid_field_timeFormatTwentyFourHour
                              .tr(),
                          timeFormatPB: TimeFormatPB.TwentyFourHour,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TimeFormatRadioListTile extends StatelessWidget {
  const _TimeFormatRadioListTile(
      {super.key, required this.title, required this.timeFormatPB});
  final String title;
  final TimeFormatPB timeFormatPB;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return RadioListTile<TimeFormatPB>(
      dense: true,
      contentPadding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(
        title,
        style: style.textTheme.bodyMedium?.copyWith(
          color: style.colorScheme.onSurface,
        ),
      ),
      groupValue: context
          .watch<DateCellCalendarBloc>()
          .state
          .dateTypeOptionPB
          .timeFormat,
      value: timeFormatPB,
      onChanged: (format) {
        if (format == null) return;
        context
            .read<DateCellCalendarBloc>()
            .add(DateCellCalendarEvent.setTimeFormat(format));
      },
    );
  }
}
