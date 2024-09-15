import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_event_editor_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarEventEditor extends StatelessWidget {
  CalendarEventEditor({
    super.key,
    required RowMetaPB rowMeta,
    required this.layoutSettings,
    required this.databaseController,
  })  : rowController = RowController(
          rowMeta: rowMeta,
          viewId: databaseController.viewId,
          rowCache: databaseController.rowCache,
        ),
        cellBuilder =
            EditableCellBuilder(databaseController: databaseController);

  final CalendarLayoutSettingPB layoutSettings;
  final DatabaseController databaseController;
  final RowController rowController;
  final EditableCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarEventEditorBloc>(
      create: (context) => CalendarEventEditorBloc(
        fieldController: databaseController.fieldController,
        rowController: rowController,
        layoutSettings: layoutSettings,
      )..add(const CalendarEventEditorEvent.initial()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EventEditorControls(
            rowController: rowController,
            databaseController: databaseController,
          ),
          Flexible(
            child: EventPropertyList(
              fieldController: databaseController.fieldController,
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
    required this.databaseController,
  });

  final RowController rowController;
  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FlowyTooltip(
            message: LocaleKeys.calendar_duplicateEvent.tr(),
            child: FlowyIconButton(
              width: 20,
              icon: const FlowySvg(
                FlowySvgs.m_duplicate_s,
                size: Size.square(17),
              ),
              iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
              onPressed: () => context.read<CalendarBloc>().add(
                    CalendarEvent.duplicateEvent(
                      rowController.viewId,
                      rowController.rowId,
                    ),
                  ),
            ),
          ),
          const HSpace(8.0),
          FlowyIconButton(
            width: 20,
            icon: const FlowySvg(FlowySvgs.delete_s),
            iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
            onPressed: () => context.read<CalendarBloc>().add(
                  CalendarEvent.deleteEvent(
                    rowController.viewId,
                    rowController.rowId,
                  ),
                ),
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
                builder: (_) => BlocProvider.value(
                  value: context.read<ViewBloc>(),
                  child: RowDetailPage(
                    databaseController: databaseController,
                    rowController: rowController,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class EventPropertyList extends StatelessWidget {
  const EventPropertyList({
    super.key,
    required this.fieldController,
    required this.dateFieldId,
    required this.cellBuilder,
  });

  final FieldController fieldController;
  final String dateFieldId;
  final EditableCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarEventEditorBloc, CalendarEventEditorState>(
      builder: (context, state) {
        final primaryFieldId = fieldController.fieldInfos
            .firstWhereOrNull((fieldInfo) => fieldInfo.isPrimary)!
            .id;
        final reorderedList = List<CellContext>.from(state.cells)
          ..retainWhere((cell) => cell.fieldId != primaryFieldId);

        final primaryCellContext = state.cells
            .firstWhereOrNull((cell) => cell.fieldId == primaryFieldId);
        final dateFieldIndex =
            reorderedList.indexWhere((cell) => cell.fieldId == dateFieldId);

        if (primaryCellContext == null || dateFieldIndex == -1) {
          return const SizedBox.shrink();
        }

        reorderedList.insert(0, reorderedList.removeAt(dateFieldIndex));

        final children = [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: cellBuilder.buildCustom(
              primaryCellContext,
              skinMap: EditableCellSkinMap(textSkin: _TitleTextCellSkin()),
            ),
          ),
          ...reorderedList.map(
            (cellContext) => PropertyCell(
              fieldController: fieldController,
              cellContext: cellContext,
              cellBuilder: cellBuilder,
            ),
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
  const PropertyCell({
    super.key,
    required this.fieldController,
    required this.cellContext,
    required this.cellBuilder,
  });

  final FieldController fieldController;
  final CellContext cellContext;
  final EditableCellBuilder cellBuilder;

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<PropertyCell> {
  @override
  Widget build(BuildContext context) {
    final fieldInfo =
        widget.fieldController.getField(widget.cellContext.fieldId)!;
    final cell = widget.cellBuilder
        .buildStyled(widget.cellContext, EditableCellStyle.desktopRowDetail);

    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => cell.requestFocus.notify(),
      child: AccessoryHover(
        fieldType: fieldInfo.fieldType,
        child: cell,
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            height: 28,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Row(
                children: [
                  FlowySvg(
                    fieldInfo.fieldType.svgData,
                    color: Theme.of(context).hintColor,
                    size: const Size.square(14),
                  ),
                  const HSpace(4.0),
                  Expanded(
                    child: FlowyText.regular(
                      fieldInfo.name,
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
}

class _TitleTextCellSkin extends IEditableTextCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TextCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return FlowyTextField(
      controller: textEditingController,
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
      focusNode: focusNode,
      hintText: LocaleKeys.calendar_defaultNewCalendarTitle.tr(),
      onEditingComplete: () {
        bloc.add(TextCellEvent.updateText(textEditingController.text));
      },
    );
  }
}
