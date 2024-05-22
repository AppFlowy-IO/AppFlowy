import 'package:appflowy/mobile/presentation/database/card/card_detail/mobile_card_detail_screen.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/calendar_card_cell_style.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../application/calendar_bloc.dart';

import 'calendar_event_editor.dart';

class EventCard extends StatefulWidget {
  const EventCard({
    super.key,
    required this.databaseController,
    required this.event,
    required this.constraints,
    required this.autoEdit,
    this.isDraggable = true,
    this.padding = EdgeInsets.zero,
  });

  final DatabaseController databaseController;
  final CalendarDayEvent event;
  final BoxConstraints constraints;
  final bool autoEdit;
  final bool isDraggable;
  final EdgeInsets padding;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final PopoverController _popoverController = PopoverController();

  String get viewId => widget.databaseController.viewId;
  RowCache get rowCache => widget.databaseController.rowCache;

  @override
  void initState() {
    super.initState();
    if (widget.autoEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _popoverController.show();
        context
            .read<CalendarBloc>()
            .add(const CalendarEvent.newEventPopupDisplayed());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowInfo = rowCache.getRow(widget.event.eventId);
    if (rowInfo == null) {
      return const SizedBox.shrink();
    }

    final cellBuilder = CardCellBuilder(
      databaseController: widget.databaseController,
    );

    Widget card = RowCard(
      // Add the key here to make sure the card is rebuilt when the cells
      // in this row are updated.
      key: ValueKey(widget.event.eventId),
      fieldController: widget.databaseController.fieldController,
      rowMeta: rowInfo.rowMeta,
      viewId: viewId,
      rowCache: rowCache,
      isEditing: false,
      cellBuilder: cellBuilder,
      onTap: (context) {
        if (PlatformExtension.isMobile) {
          context.push(
            MobileRowDetailPage.routeName,
            extra: {
              MobileRowDetailPage.argRowId: rowInfo.rowId,
              MobileRowDetailPage.argDatabaseController:
                  widget.databaseController,
            },
          );
        } else {
          _popoverController.show();
        }
      },
      styleConfiguration: RowCardStyleConfiguration(
        cellStyleMap: desktopCalendarCardCellStyleMap(context),
        showAccessory: false,
        cardPadding: const EdgeInsets.all(6),
        hoverStyle: HoverStyle(
          hoverColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0x0F1F2329)
              : const Color(0x0FEFF4FB),
          foregroundColorOnHover: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onStartEditing: () {},
      onEndEditing: () {},
    );

    final decoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.fromBorderSide(
        BorderSide(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xffd0d3d6)
              : const Color(0xff59647a),
          width: 0.5,
        ),
      ),
      borderRadius: Corners.s6Border,
      boxShadow: [
        BoxShadow(
          spreadRadius: -2,
          color: const Color(0xFF1F2329).withOpacity(0.02),
          blurRadius: 2,
        ),
        BoxShadow(
          color: const Color(0xFF1F2329).withOpacity(0.02),
          blurRadius: 4,
        ),
        BoxShadow(
          spreadRadius: 2,
          color: const Color(0xFF1F2329).withOpacity(0.02),
          blurRadius: 8,
        ),
      ],
    );

    card = AppFlowyPopover(
      triggerActions: PopoverTriggerFlags.none,
      direction: PopoverDirection.rightWithCenterAligned,
      controller: _popoverController,
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 348),
      asBarrier: true,
      margin: EdgeInsets.zero,
      offset: const Offset(10.0, 0),
      popupBuilder: (_) {
        final settings = context.watch<CalendarBloc>().state.settings;
        if (settings == null) {
          return const SizedBox.shrink();
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: context.read<CalendarBloc>(),
            ),
            BlocProvider.value(
              value: context.read<ViewBloc>(),
            ),
          ],
          child: CalendarEventEditor(
            databaseController: widget.databaseController,
            rowMeta: widget.event.event.rowMeta,
            layoutSettings: settings,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: widget.padding,
          decoration: decoration,
          child: card,
        ),
      ),
    );

    if (widget.isDraggable) {
      return Draggable<CalendarDayEvent>(
        data: widget.event,
        feedback: Container(
          constraints: BoxConstraints(
            maxWidth: widget.constraints.maxWidth - 8.0,
          ),
          decoration: decoration,
          child: Opacity(
            opacity: 0.6,
            child: card,
          ),
        ),
        child: card,
      );
    }

    return card;
  }
}
