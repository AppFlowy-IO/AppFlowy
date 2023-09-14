import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/widgets/card/bloc/text_card_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/number_card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/url_card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/calendar_bloc.dart';
import 'calendar_page.dart';

class EventCard extends StatelessWidget {
  final CalendarDayEvent event;
  final String viewId;
  final RowCache rowCache;
  final BoxConstraints constraints;

  const EventCard({
    required this.event,
    required this.viewId,
    required this.rowCache,
    required this.constraints,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rowInfo = rowCache.getRow(event.eventId);
    final styles = <FieldType, CardCellStyle>{
      FieldType.Number: NumberCardCellStyle(10),
      FieldType.URL: URLCardCellStyle(10),
    };
    final cellBuilder = CardCellBuilder<CalendarDayEvent>(
      rowCache.cellCache,
      styles: styles,
    );
    final renderHook = _calendarEventCardRenderHook(context);

    final card = RowCard<CalendarDayEvent>(
      // Add the key here to make sure the card is rebuilt when the cells
      // in this row are updated.
      key: ValueKey(event.eventId),
      rowMeta: rowInfo!.rowMeta,
      viewId: viewId,
      rowCache: rowCache,
      cardData: event,
      isEditing: false,
      cellBuilder: cellBuilder,
      openCard: (context) => showEventDetails(
        context: context,
        event: event.event,
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
        child: DecoratedBox(
          decoration: decoration.copyWith(
            color: AFThemeExtension.of(context).lightGreyHover,
          ),
          child: card,
        ),
      ),
      child: DecoratedBox(
        decoration: decoration,
        child: card,
      ),
    );
  }

  RowCardRenderHook<CalendarDayEvent> _calendarEventCardRenderHook(
    BuildContext context,
  ) {
    final renderHook = RowCardRenderHook<CalendarDayEvent>();
    renderHook.addTextCellHook((cellData, eventData, _) {
      return BlocBuilder<TextCardCellBloc, TextCardCellState>(
        builder: (context, state) {
          final isTitle = context
              .read<TextCardCellBloc>()
              .cellController
              .fieldInfo
              .isPrimary;
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
              fontSize: 11,
              maxLines: null, // Enable multiple lines
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
