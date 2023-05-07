import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/number_card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/url_card_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return ChangeNotifierProvider(
      create: (_) => _CardEnterNotifier(),
      builder: (context, child) {
        Widget? multipleCards;
        if (events.isNotEmpty) {
          multipleCards = Flexible(
            child: ListView.separated(
              itemBuilder: (BuildContext context, int index) =>
                  _buildCard(context, events[index]),
              itemCount: events.length,
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              separatorBuilder: (BuildContext context, int index) =>
                  VSpace(GridSize.typeOptionSeparatorHeight),
            ),
          );
        }

        final child = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              date: date,
              isInMonth: isInMonth,
              isToday: isToday,
              onCreate: () => onCreateEvent(date),
            ),

            // Add a separator between the header and the content.
            VSpace(GridSize.typeOptionSeparatorHeight),

            // Use SizedBox instead of ListView if there are no cards.
            multipleCards ?? const SizedBox(),
          ],
        );

        return Container(
          color: backgroundColor,
          child: GestureDetector(
            onDoubleTap: () => onCreateEvent(date),
            child: MouseRegion(
              cursor: SystemMouseCursors.basic,
              onEnter: (p) => notifyEnter(context, true),
              onExit: (p) => notifyEnter(context, false),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  GestureDetector _buildCard(BuildContext context, CalendarDayEvent event) {
    final styles = <FieldType, CardCellStyle>{
      FieldType.Number: NumberCardCellStyle(10),
      FieldType.URL: URLCardCellStyle(10),
    };

    final cellBuilder = CardCellBuilder<String>(
      _rowCache.cellCache,
      styles: styles,
    );

    final rowInfo = _rowCache.getRow(event.eventId);
    final renderHook = RowCardRenderHook<String>();
    renderHook.addTextCellHook((cellData, primaryFieldId, _) {
      if (cellData.isEmpty) {
        return const SizedBox();
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

    // renderHook.addDateFieldHook((cellData, cardData) {

    final card = RowCard<String>(
      // Add the key here to make sure the card is rebuilt when the cells
      // in this row are updated.
      key: ValueKey(event.eventId),
      row: rowInfo!.rowPB,
      viewId: viewId,
      rowCache: _rowCache,
      cardData: event.dateFieldId,
      isEditing: false,
      cellBuilder: cellBuilder,
      openCard: (context) => showEventDetails(
        context: context,
        event: event,
        viewId: viewId,
        rowCache: _rowCache,
      ),
      styleConfiguration: const RowCardStyleConfiguration(
        showAccessory: false,
        cellPadding: EdgeInsets.zero,
      ),
      renderHook: renderHook,
      onStartEditing: () {},
      onEndEditing: () {},
    );

    return GestureDetector(
      onTap: () => showEventDetails(
        context: context,
        event: event,
        viewId: viewId,
        rowCache: _rowCache,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
            borderRadius: Corners.s6Border,
          ),
          child: card,
        ),
      ),
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
  final VoidCallback onCreate;
  const _Header({
    required this.isToday,
    required this.isInMonth,
    required this.date,
    required this.onCreate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<_CardEnterNotifier>(
      builder: (context, notifier, _) {
        final badge = _DayBadge(
          isToday: isToday,
          isInMonth: isInMonth,
          date: date,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              if (notifier.onEnter) _NewEventButton(onClick: onCreate),
              const Spacer(),
              badge,
            ],
          ),
        );
      },
    );
  }
}

class _NewEventButton extends StatelessWidget {
  final VoidCallback onClick;
  const _NewEventButton({
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      onPressed: onClick,
      iconPadding: EdgeInsets.zero,
      icon: const FlowySvg(name: "home/add"),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 22,
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
    String monthString =
        DateFormat("MMM ", context.locale.toLanguageTag()).format(date);
    String dayString = date.day.toString();

    if (!isInMonth) {
      dayTextColor = Theme.of(context).disabledColor;
    }
    if (isToday) {
      dayTextColor = Theme.of(context).colorScheme.onPrimary;
    }

    return Row(
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
