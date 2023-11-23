import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/mobile_card_detail_screen.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/number_card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/url_card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
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
    required this.fieldController,
    required this.event,
    required this.viewId,
    required this.rowCache,
    required this.constraints,
    required this.autoEdit,
    this.isDraggable = true,
  });

  final FieldController fieldController;
  final CalendarDayEvent event;
  final String viewId;
  final RowCache rowCache;
  final BoxConstraints constraints;
  final bool autoEdit;
  final bool isDraggable;

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late final PopoverController _popoverController;

  @override
  void initState() {
    super.initState();
    _popoverController = PopoverController();
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
    final rowInfo = widget.rowCache.getRow(widget.event.eventId);
    if (rowInfo == null) {
      return const SizedBox.shrink();
    }
    final styles = <FieldType, CardCellStyle>{
      FieldType.Number: NumberCardCellStyle(10),
      FieldType.URL: URLCardCellStyle(10),
    };
    final cellBuilder = CardCellBuilder<CalendarDayEvent>(
      widget.rowCache.cellCache,
      styles: styles,
    );
    final renderHook = _calendarEventCardRenderHook(context);

    Widget card = RowCard<CalendarDayEvent>(
      // Add the key here to make sure the card is rebuilt when the cells
      // in this row are updated.
      key: ValueKey(widget.event.eventId),
      rowMeta: rowInfo.rowMeta,
      viewId: widget.viewId,
      rowCache: widget.rowCache,
      cardData: widget.event,
      isEditing: false,
      cellBuilder: cellBuilder,
      openCard: (context) {
        if (PlatformExtension.isMobile) {
          final dataController = RowController(
            rowMeta: rowInfo.rowMeta,
            viewId: widget.viewId,
            rowCache: widget.rowCache,
          );

          context.push(
            MobileCardDetailScreen.routeName,
            extra: {
              MobileCardDetailScreen.argRowController: dataController,
              MobileCardDetailScreen.argFieldController: widget.fieldController,
            },
          );
        } else {
          _popoverController.show();
        }
      },
      styleConfiguration: RowCardStyleConfiguration(
        showAccessory: false,
        cellPadding: EdgeInsets.zero,
        cardPadding: const EdgeInsets.all(6),
        hoverStyle: HoverStyle(
          hoverColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0x0F1F2329)
              : const Color(0x0FEFF4FB),
          foregroundColorOnHover: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      renderHook: renderHook,
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
          spreadRadius: 0,
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
      popupBuilder: (BuildContext popoverContext) {
        final settings = context.watch<CalendarBloc>().state.settings.fold(
              () => null,
              (layoutSettings) => layoutSettings,
            );
        if (settings == null) {
          return const SizedBox.shrink();
        }
        return CalendarEventEditor(
          fieldController: widget.fieldController,
          rowCache: widget.rowCache,
          rowMeta: widget.event.event.rowMeta,
          viewId: widget.viewId,
          layoutSettings: settings,
        );
      },
      child: DecoratedBox(
        decoration: decoration,
        child: card,
      ),
    );

    if (widget.isDraggable) {
      return Draggable<CalendarDayEvent>(
        data: widget.event,
        feedback: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.constraints.maxWidth - 8.0,
          ),
          child: Opacity(
            opacity: 0.6,
            child: DecoratedBox(
              decoration: decoration,
              child: card,
            ),
          ),
        ),
        child: card,
      );
    }

    return card;
  }

  RowCardRenderHook<CalendarDayEvent> _calendarEventCardRenderHook(
    BuildContext context,
  ) {
    final renderHook = RowCardRenderHook<CalendarDayEvent>();
    renderHook.addTextCellHook((cellData, eventData, _) {
      return BlocBuilder<TextCellBloc, TextCellState>(
        builder: (context, state) {
          final isTitle =
              context.read<TextCellBloc>().cellController.fieldInfo.isPrimary;
          final text = isTitle && cellData.isEmpty
              ? LocaleKeys.grid_row_titlePlaceholder.tr()
              : cellData;

          if (text.isEmpty) {
            return const SizedBox.shrink();
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: FlowyText.medium(
              text,
              textAlign: TextAlign.left,
              fontSize: isTitle ? 11 : 10,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
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
                ),
            ],
          ),
        ),
      );
    });

    renderHook.addTimestampCellHook((cellData, cardData, _) {
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
                  cellData.dateTime,
                  fontSize: 10,
                  color: Theme.of(context).hintColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
