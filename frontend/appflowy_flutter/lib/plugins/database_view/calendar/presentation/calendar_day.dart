import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/text_card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../application/calendar_bloc.dart';

class CalendarDayCard extends StatelessWidget {
  final String viewId;
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  final RowCache _rowCache;
  final CardCellBuilder _cellBuilder;
  final List<CalendarDayEvent> events;
  final void Function(DateTime) onCreateEvent;

  CalendarDayCard({
    required this.viewId,
    required this.isToday,
    required this.isInMonth,
    required this.date,
    required this.onCreateEvent,
    required RowCache rowCache,
    required this.events,
    Key? key,
  })  : _rowCache = rowCache,
        _cellBuilder = CardCellBuilder(rowCache.cellCache),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).colorScheme.surface;
    if (!isInMonth) {
      backgroundColor = AFThemeExtension.of(context).lightGreyHover;
    }

    return ChangeNotifierProvider(
      create: (_) => _CardEnterNotifier(),
      builder: ((context, child) {
        final children = events.map((event) {
          return _DayEventCell(
            event: event,
            viewId: viewId,
            onClick: () => _showRowDetailPage(event, context),
            child: _cellBuilder.buildCell(
              cellId: event.cellId,
              styles: {FieldType.RichText: TextCardCellStyle(10)},
            ),
          );
        }).toList();

        final child = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _Header(
                date: date,
                isInMonth: isInMonth,
                isToday: isToday,
                onCreate: () => onCreateEvent(date),
              ),
            ),
            VSpace(GridSize.typeOptionSeparatorHeight),
            Flexible(
              child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  return children[index];
                },
                itemCount: children.length,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                separatorBuilder: (BuildContext context, int index) =>
                    VSpace(GridSize.typeOptionSeparatorHeight),
              ),
            ),
          ],
        );

        return Container(
          color: backgroundColor,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (p) => notifyEnter(context, true),
            onExit: (p) => notifyEnter(context, false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: child,
            ),
          ),
        );
      }),
    );
  }

  void _showRowDetailPage(CalendarDayEvent event, BuildContext context) {
    final dataController = RowController(
      rowId: event.cellId.rowId,
      viewId: viewId,
      rowCache: _rowCache,
    );

    FlowyOverlay.show(
      context: context,
      builder: (BuildContext context) {
        return RowDetailPage(
          cellBuilder: GridCellBuilder(
            cellCache: _rowCache.cellCache,
          ),
          dataController: dataController,
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

class _DayEventCell extends StatelessWidget {
  final String viewId;
  final CalendarDayEvent event;
  final VoidCallback onClick;
  final Widget child;
  const _DayEventCell({
    required this.viewId,
    required this.event,
    required this.onClick,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      child: GestureDetector(
        onTap: onClick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
            borderRadius: Corners.s6Border,
          ),
          child: child,
        ),
      ),
    );
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
        return Row(
          children: [
            if (notifier.onEnter) _NewEventButton(onClick: onCreate),
            const Spacer(),
            badge,
          ],
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
      icon: svgWidget(
        "home/add",
        color: Theme.of(context).iconTheme.color,
      ),
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
    Color dayTextColor = Theme.of(context).colorScheme.onSurface;
    String dayString = date.day == 1
        ? DateFormat('MMM d', context.locale.toLanguageTag()).format(date)
        : date.day.toString();

    if (isToday) {
      dayTextColor = Theme.of(context).colorScheme.onPrimary;
    }
    if (!isInMonth) {
      dayTextColor = Theme.of(context).disabledColor;
    }

    Widget day = Container(
      decoration: BoxDecoration(
        color: isToday ? Theme.of(context).colorScheme.primary : null,
        borderRadius: Corners.s6Border,
      ),
      padding: GridSize.typeOptionContentInsets,
      child: FlowyText.medium(
        dayString,
        color: dayTextColor,
      ),
    );

    return day;
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
