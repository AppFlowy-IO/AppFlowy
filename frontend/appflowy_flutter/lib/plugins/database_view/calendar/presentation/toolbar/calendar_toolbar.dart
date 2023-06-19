import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/calendar/application/unschedule_event_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_button.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarSettingBar extends StatelessWidget {
  final DatabaseController databaseController;
  const CalendarSettingBar({
    required this.databaseController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          UnscheduleEventsButton(databaseController: databaseController),
          SettingButton(
            databaseController: databaseController,
          ),
        ],
      ),
    );
  }
}

class UnscheduleEventsButton extends StatefulWidget {
  final DatabaseController databaseController;
  const UnscheduleEventsButton({
    required this.databaseController,
    Key? key,
  }) : super(key: key);

  @override
  State<UnscheduleEventsButton> createState() => _UnscheduleEventsButtonState();
}

class _UnscheduleEventsButtonState extends State<UnscheduleEventsButton> {
  late final PopoverController _popoverController;
  late final UnscheduleEventsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = UnscheduleEventsBloc(databaseController: widget.databaseController)
      ..add(const UnscheduleEventsEvent.initial());
    _popoverController = PopoverController();
  }

  @override
  dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithCenterAligned,
      controller: _popoverController,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 600),
      child: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<UnscheduleEventsBloc, UnscheduleEventsState>(
          buildWhen: (previous, current) =>
              previous.unscheduleEvents.length !=
              current.unscheduleEvents.length,
          builder: (context, state) {
            return FlowyTextButton(
              "${LocaleKeys.calendar_settings_noDateTitle.tr()} (${state.unscheduleEvents.length})",
              fillColor: Colors.transparent,
              hoverColor: AFThemeExtension.of(context).lightGreyHover,
              padding: GridSize.typeOptionContentInsets,
            );
          },
        ),
      ),
      popupBuilder: (context) {
        return UnscheduleEventsList(
          viewId: _bloc.viewId,
          rowCache: _bloc.rowCache,
          controller: _popoverController,
          unscheduleEvents: _bloc.state.unscheduleEvents,
        );
      },
    );
  }
}

class UnscheduleEventsList extends StatelessWidget {
  final String viewId;
  final RowCache rowCache;
  final PopoverController controller;
  final List<CalendarEventPB> unscheduleEvents;
  const UnscheduleEventsList({
    required this.viewId,
    required this.controller,
    required this.unscheduleEvents,
    required this.rowCache,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: FlowyText.medium(
          LocaleKeys.calendar_settings_clickToAdd.tr(),
          color: Theme.of(context).hintColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const VSpace(6),
      ...unscheduleEvents.map(
        (e) => UnscheduledEventCell(
          event: e,
          onPressed: () {
            showEventDetails(
              context: context,
              event: e,
              viewId: viewId,
              rowCache: rowCache,
            );
            controller.close();
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
  }
}

class UnscheduledEventCell extends StatelessWidget {
  final CalendarEventPB event;
  final VoidCallback onPressed;
  const UnscheduledEventCell({
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
