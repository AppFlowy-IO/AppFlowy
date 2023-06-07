import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/number_card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/url_card_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../widgets/row/cells/select_option_cell/extension.dart';
import '../application/calendar_bloc.dart';
import 'calendar_page.dart';

class CalendarDayCard extends StatelessWidget {
  final String viewId;
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  final RowCache _rowCache;
  final List<CalendarDayEvent> events;
  final void Function(DateTime) onCreateEvent;

  const CalendarDayCard({
    required this.viewId,
    required this.isToday,
    required this.isInMonth,
    required this.date,
    required this.onCreateEvent,
    required RowCache rowCache,
    required this.events,
    Key? key,
  })  : _rowCache = rowCache,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).colorScheme.surface;
    if (!isInMonth) {
      backgroundColor = AFThemeExtension.of(context).lightGreyHover;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return ChangeNotifierProvider(
          create: (_) => _CardEnterNotifier(),
          builder: (context, child) {
            final child = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Header(
                  date: date,
                  isInMonth: isInMonth,
                  isToday: isToday,
                ),

                // Add a separator between the header and the content.
                VSpace(GridSize.typeOptionSeparatorHeight),

                // List of cards or empty space
                if (events.isNotEmpty)
                  _EventList(
                    events: events,
                    viewId: viewId,
                    rowCache: _rowCache,
                    constraints: constraints,
                  ),
              ],
            );

            return Stack(
              children: <Widget>[
                GestureDetector(
                  onDoubleTap: () => onCreateEvent(date),
                  child: Container(color: backgroundColor),
                ),
                DragTarget<CalendarDayEvent>(
                  builder: (context, candidate, __) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (candidate.isNotEmpty)
                          Container(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: child,
                        )
                      ],
                    );
                  },
                  onWillAccept: (CalendarDayEvent? event) {
                    if (event == null) {
                      return false;
                    }
                    return !isSameDay(event.date, date);
                  },
                  onAccept: (CalendarDayEvent event) {
                    context
                        .read<CalendarBloc>()
                        .add(CalendarEvent.moveEvent(event, date));
                  },
                ),
                _NewEventButton(onCreate: () => onCreateEvent(date)),
                MouseRegion(
                  onEnter: (p) => notifyEnter(context, true),
                  onExit: (p) => notifyEnter(context, false),
                  opaque: false,
                  hitTestBehavior: HitTestBehavior.translucent,
                ),
              ],
            );
          },
        );
      },
    );
  }

  notifyEnter(BuildContext context, bool isEnter) {
    Provider.of<_CardEnterNotifier>(
      context,
      listen: false,
    ).onEnter = isEnter;
  }
}

class _Header extends StatelessWidget {
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  const _Header({
    required this.isToday,
    required this.isInMonth,
    required this.date,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: _DayBadge(
        isToday: isToday,
        isInMonth: isInMonth,
        date: date,
      ),
    );
  }
}

class _NewEventButton extends StatelessWidget {
  final VoidCallback onCreate;
  const _NewEventButton({required this.onCreate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<_CardEnterNotifier>(
      builder: (context, notifier, _) {
        if (!notifier.onEnter) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: FlowyIconButton(
            onPressed: onCreate,
            iconPadding: EdgeInsets.zero,
            icon: const FlowySvg(name: "home/add"),
            fillColor: Theme.of(context).colorScheme.background,
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            width: 22,
          ),
        );
      },
    );
  }
}

class _DayBadge extends StatelessWidget {
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  const _DayBadge({
    required this.isToday,
    required this.isInMonth,
    required this.date,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color dayTextColor = Theme.of(context).colorScheme.onBackground;
    final String monthString =
        DateFormat("MMM ", context.locale.toLanguageTag()).format(date);
    final String dayString = date.day.toString();

    if (!isInMonth) {
      dayTextColor = Theme.of(context).disabledColor;
    }
    if (isToday) {
      dayTextColor = Theme.of(context).colorScheme.onPrimary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (date.day == 1) FlowyText.medium(monthString),
        Container(
          decoration: BoxDecoration(
            color: isToday ? Theme.of(context).colorScheme.primary : null,
            borderRadius: Corners.s6Border,
          ),
          width: isToday ? 26 : null,
          height: isToday ? 26 : null,
          padding: GridSize.typeOptionContentInsets,
          child: Center(
            child: FlowyText.medium(
              dayString,
              color: dayTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventList extends StatelessWidget {
  final List<CalendarDayEvent> events;
  final String viewId;
  final RowCache rowCache;
  final BoxConstraints constraints;

  const _EventList({
    required this.events,
    required this.viewId,
    required this.rowCache,
    required this.constraints,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ListView.separated(
        itemBuilder: (BuildContext context, int index) => _EventCard(
          event: events[index],
          viewId: viewId,
          rowCache: rowCache,
          constraints: constraints,
        ),
        itemCount: events.length,
        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
        separatorBuilder: (BuildContext context, int index) =>
            VSpace(GridSize.typeOptionSeparatorHeight),
        shrinkWrap: true,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarDayEvent event;
  final String viewId;
  final RowCache rowCache;
  final BoxConstraints constraints;

  const _EventCard({
    required this.event,
    required this.viewId,
    required this.rowCache,
    required this.constraints,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rowInfo = rowCache.getRow(event.eventId);
    final styles = <FieldType, CardCellStyle>{
      FieldType.Number: NumberCardCellStyle(10),
      FieldType.URL: URLCardCellStyle(10),
    };
    final cellBuilder = CardCellBuilder<String>(
      rowCache.cellCache,
      styles: styles,
    );
    final renderHook = _calendarEventCardRenderHook(context);

    final card = RowCard<String>(
      // Add the key here to make sure the card is rebuilt when the cells
      // in this row are updated.
      key: ValueKey(event.eventId),
      row: rowInfo!.rowPB,
      viewId: viewId,
      rowCache: rowCache,
      cardData: event.dateFieldId,
      isEditing: false,
      cellBuilder: cellBuilder,
      openCard: (context) => showEventDetails(
        context: context,
        event: event,
        viewId: viewId,
        rowCache: rowCache,
      ),
      styleConfiguration: RowCardStyleConfiguration(
        showAccessory: false,
        cellPadding: EdgeInsets.zero,
        hoverStyle: HoverStyle(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          foregroundColorOnHover: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      renderHook: renderHook,
      onStartEditing: () {},
      onEndEditing: () {},
    );

    final decoration = BoxDecoration(
      border: Border.fromBorderSide(
        BorderSide(color: Theme.of(context).dividerColor),
      ),
      borderRadius: Corners.s6Border,
    );

    return Draggable<CalendarDayEvent>(
      data: event,
      feedback: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: constraints.maxWidth - 16.0,
        ),
        child: Container(
          decoration: decoration.copyWith(
            color: AFThemeExtension.of(context).lightGreyHover,
          ),
          child: card,
        ),
      ),
      child: Container(
        decoration: decoration,
        child: card,
      ),
    );
  }

  RowCardRenderHook<String> _calendarEventCardRenderHook(BuildContext context) {
    final renderHook = RowCardRenderHook<String>();
    renderHook.addTextCellHook((cellData, primaryFieldId, _) {
      if (cellData.isEmpty) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: FlowyText.medium(
          cellData,
          textAlign: TextAlign.left,
          fontSize: 11,
          maxLines: null, // Enable multiple lines
        ),
      );
    });

    renderHook.addDateCellHook((cellData, cardData, _) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 3,
                child: FlowyText.regular(
                  cellData.date,
                  fontSize: 10,
                  color: Theme.of(context).hintColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cellData.includeTime)
                Flexible(
                  child: FlowyText.regular(
                    cellData.time,
                    fontSize: 10,
                    color: Theme.of(context).hintColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
            ],
          ),
        ),
      );
    });

    renderHook.addSelectOptionHook((selectedOptions, cardData, _) {
      if (selectedOptions.isEmpty) {
        return const SizedBox.shrink();
      }
      final children = selectedOptions.map(
        (option) {
          return SelectOptionTag.fromOption(
            context: context,
            option: option,
          );
        },
      ).toList();

      return IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox.expand(
            child: Wrap(spacing: 4, runSpacing: 4, children: children),
          ),
        ),
      );
    });

    return renderHook;
  }
}

class _CardEnterNotifier extends ChangeNotifier {
  bool _onEnter = false;

  _CardEnterNotifier();

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}
