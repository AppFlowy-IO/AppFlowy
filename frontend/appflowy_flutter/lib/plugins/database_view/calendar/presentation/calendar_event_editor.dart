import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_event_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarEventEditor extends StatelessWidget {
  final RowController rowController;
  final FieldController fieldController;
  final CalendarLayoutSettingPB layoutSettings;
  final GridCellBuilder cellBuilder;

  CalendarEventEditor({
    super.key,
    required RowCache rowCache,
    required RowMetaPB rowMeta,
    required String viewId,
    required this.layoutSettings,
    required this.fieldController,
  })  : rowController = RowController(
          rowMeta: rowMeta,
          viewId: viewId,
          rowCache: rowCache,
        ),
        cellBuilder = GridCellBuilder(cellCache: rowCache.cellCache);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarEventEditorBloc>(
      create: (context) => CalendarEventEditorBloc(
        rowController: rowController,
        layoutSettings: layoutSettings,
      )..add(const CalendarEventEditorEvent.initial()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EventEditorControls(
            rowController: rowController,
            fieldController: fieldController,
          ),
          Flexible(
            child: EventPropertyList(
              dateFieldId: layoutSettings.fieldId,
              cellBuilder: cellBuilder,
            ),
          ),
        ],
      ),
    );
  }
}

class EventEditorControls extends StatelessWidget {
  const EventEditorControls({
    super.key,
    required this.rowController,
    required this.fieldController,
  });

  final RowController rowController;
  final FieldController fieldController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FlowyIconButton(
            width: 20,
            icon: const FlowySvg(FlowySvgs.delete_s),
            iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
            onPressed: () => context
                .read<CalendarEventEditorBloc>()
                .add(const CalendarEventEditorEvent.delete()),
          ),
          const HSpace(8.0),
          FlowyIconButton(
            width: 20,
            icon: const FlowySvg(FlowySvgs.full_view_s),
            iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              PopoverContainer.of(context).close();
              FlowyOverlay.show(
                context: context,
                builder: (BuildContext context) {
                  return RowDetailPage(
                    fieldController: fieldController,
                    cellBuilder: GridCellBuilder(
                      cellCache: rowController.cellCache,
                    ),
                    rowController: rowController,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class EventPropertyList extends StatelessWidget {
  final String dateFieldId;
  final GridCellBuilder cellBuilder;
  const EventPropertyList({
    super.key,
    required this.dateFieldId,
    required this.cellBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarEventEditorBloc, CalendarEventEditorState>(
      builder: (context, state) {
        final reorderedList = List<DatabaseCellContext>.from(state.cells)
          ..retainWhere((cell) => !cell.fieldInfo.isPrimary);

        final primaryCellContext =
            state.cells.firstWhereOrNull((cell) => cell.fieldInfo.isPrimary);
        final dateFieldIndex =
            reorderedList.indexWhere((cell) => cell.fieldId == dateFieldId);

        if (primaryCellContext == null || dateFieldIndex == -1) {
          return const SizedBox.shrink();
        }

        reorderedList.insert(0, reorderedList.removeAt(dateFieldIndex));

        final children = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: cellBuilder.build(
              primaryCellContext,
              style: GridTextCellStyle(
                cellPadding: EdgeInsets.zero,
                placeholder: LocaleKeys.calendar_defaultNewCalendarTitle.tr(),
                textStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11, overflow: TextOverflow.ellipsis),
                autofocus: true,
                useRoundedBorder: true,
              ),
            ),
          ),
          ...reorderedList.map(
            (cell) => PropertyCell(cellContext: cell, cellBuilder: cellBuilder),
          ),
        ];

        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16.0),
          children: children,
        );
      },
    );
  }
}

class PropertyCell extends StatefulWidget {
  final DatabaseCellContext cellContext;
  final GridCellBuilder cellBuilder;
  const PropertyCell({
    required this.cellContext,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<PropertyCell> {
  @override
  Widget build(BuildContext context) {
    final style = _customCellStyle(widget.cellContext.fieldType);
    final cell = widget.cellBuilder.build(widget.cellContext, style: style);

    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => cell.requestFocus.notify(),
      child: AccessoryHover(
        fieldType: widget.cellContext.fieldType,
        child: cell,
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            height: 28,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Row(
                children: [
                  FlowySvg(
                    widget.cellContext.fieldType.icon(),
                    color: Theme.of(context).hintColor,
                    size: const Size.square(14),
                  ),
                  const HSpace(4.0),
                  Expanded(
                    child: FlowyText.regular(
                      widget.cellContext.fieldInfo.name,
                      color: Theme.of(context).hintColor,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const HSpace(8),
          Expanded(child: gesture),
        ],
      ),
    );
  }

  GridCellStyle? _customCellStyle(FieldType fieldType) {
    switch (fieldType) {
      case FieldType.Checkbox:
        return GridCheckboxCellStyle(
          cellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        );
      case FieldType.DateTime:
        return DateCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
          alignment: Alignment.centerLeft,
          cellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        );
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return TimestampCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
          alignment: Alignment.centerLeft,
          cellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        );
      case FieldType.MultiSelect:
        return SelectOptionCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
          cellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        );
      case FieldType.Checklist:
        return ChecklistCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
          cellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        );
      case FieldType.Number:
        return GridNumberCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        );
      case FieldType.RichText:
        return GridTextCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        );
      case FieldType.SingleSelect:
        return SelectOptionCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
          cellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        );
      case FieldType.URL:
        return GridURLCellStyle(
          placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
          accessoryTypes: [
            GridURLCellAccessoryType.copyURL,
            GridURLCellAccessoryType.visitURL,
          ],
        );
    }
    throw UnimplementedError;
  }
}
