import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_button.dart';
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
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const _UnscheduleEventsButton(),
          SettingButton(
            databaseController: context.read<CalendarBloc>().databaseController,
          ),
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
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 600),
          child: FlowyTextButton(
            "${LocaleKeys.calendar_settings_noDateTitle.tr()} (${unscheduledEvents.length})",
            fillColor: Colors.transparent,
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            padding: GridSize.typeOptionContentInsets,
          ),
          popupBuilder: (context) {
            final cells = <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: FlowyText.medium(
                  // LocaleKeys.calendar_settings_noDateHint.tr(),
                  LocaleKeys.calendar_settings_clickToAdd.tr(),
                  color: Theme.of(context).hintColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const VSpace(6),
              ...unscheduledEvents.map(
                (e) => _UnscheduledEventItem(
                  event: e,
                  onPressed: () {
                    showEventDetails(
                      context: context,
                      event: e.event!,
                      viewId: viewId,
                      rowCache: rowCache,
                    );
                    _controller.close();
                  },
                ),
              )
            ];
            return ListView.separated(
              itemBuilder: (context, index) => cells[index],
              itemCount: cells.length,
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
      child: FlowyButton(
        text: FlowyText.medium(
          event.title.isEmpty
              ? LocaleKeys.calendar_defaultNewCalendarTitle.tr()
              : event.title,
        ),
        onTap: onPressed,
      ),
    );
  }
}
