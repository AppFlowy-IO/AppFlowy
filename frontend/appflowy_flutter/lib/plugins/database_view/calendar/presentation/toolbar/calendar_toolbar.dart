import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/calendar_bloc.dart';
import 'calendar_setting.dart';

class CalendarToolbar extends StatelessWidget {
  const CalendarToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _UnscheduleEventsButton(),
          _SettingButton(),
        ],
      ),
    );
  }
}

class _SettingButton extends StatefulWidget {
  const _SettingButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<_SettingButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithRightAligned,
      constraints: BoxConstraints.loose(const Size(300, 400)),
      margin: EdgeInsets.zero,
      child: FlowyTextButton(
        LocaleKeys.settings_title.tr(),
        fillColor: Colors.transparent,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        padding: GridSize.typeOptionContentInsets,
      ),
      popupBuilder: (BuildContext popoverContext) {
        final bloc = context.watch<CalendarBloc>();
        final settingContext = CalendarSettingContext(
          viewId: bloc.viewId,
          fieldController: bloc.fieldController,
        );
        return CalendarSetting(
          settingContext: settingContext,
          layoutSettings: bloc.state.settings.fold(
            () => null,
            (settings) => settings,
          ),
          onUpdated: (layoutSettings) {
            if (layoutSettings == null) {
              return;
            }
            context
                .read<CalendarBloc>()
                .add(CalendarEvent.updateCalendarLayoutSetting(layoutSettings));
          },
        );
      }, // use blocbuilder
    );
  }
}

class _UnscheduleEventsButton extends StatefulWidget {
  const _UnscheduleEventsButton({Key? key}) : super(key: key);

  @override
  State<_UnscheduleEventsButton> createState() =>
      _UnscheduleEventsButtonState();
}

class _UnscheduleEventsButtonState extends State<_UnscheduleEventsButton> {
  late final PopoverController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PopoverController();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final unscheduledEvents = state.allEvents
            .where((e) => e.date == DateTime.fromMillisecondsSinceEpoch(0))
            .toList();
        final viewId = context.read<CalendarBloc>().viewId;
        final rowCache = context.read<CalendarBloc>().rowCache;
        return AppFlowyPopover(
          direction: PopoverDirection.bottomWithCenterAligned,
          controller: _controller,
          offset: const Offset(0, 8),
          child: FlowyTextButton(
            "${LocaleKeys.calendar_settings_noDateTitle.tr()} (${unscheduledEvents.length})",
            fillColor: Colors.transparent,
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            padding: GridSize.typeOptionContentInsets,
          ),
          popupBuilder: (context) {
            if (unscheduledEvents.isEmpty) {
              return SizedBox(
                height: GridSize.popoverItemHeight,
                child: Center(
                  child: FlowyText.medium(
                    LocaleKeys.calendar_settings_emptyNoDate.tr(),
                    color: Theme.of(context).hintColor,
                  ),
                ),
              );
            }
            return ListView.separated(
              itemBuilder: (context, index) => _UnscheduledEventItem(
                event: unscheduledEvents[index],
                onPressed: () {
                  showEventDetails(
                    context: context,
                    event: unscheduledEvents[index].event!,
                    viewId: viewId,
                    rowCache: rowCache,
                  );
                  _controller.close();
                },
              ),
              itemCount: unscheduledEvents.length,
              separatorBuilder: (context, index) =>
                  VSpace(GridSize.typeOptionSeparatorHeight),
              shrinkWrap: true,
            );
          },
        );
      },
    );
  }
}

class _UnscheduledEventItem extends StatelessWidget {
  final CalendarEventData<CalendarDayEvent> event;
  final VoidCallback onPressed;
  const _UnscheduledEventItem({
    required this.event,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyTextButton(
        event.title,
        fillColor: Colors.transparent,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        padding: GridSize.typeOptionContentInsets,
        onPressed: onPressed,
      ),
    );
  }
}
