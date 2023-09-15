import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_cell.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_editor.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'accessory/cell_accessory.dart';
import 'cell_builder.dart';

/// Display the row properties in a list. Only use this widget in the
/// [RowDetailPage].
class RowPropertyList extends StatelessWidget {
  final String viewId;
  final GridCellBuilder cellBuilder;
  const RowPropertyList({
    required this.viewId,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      buildWhen: (previous, current) => previous.cells != current.cells,
      builder: (context, state) {
        final children = state.cells
            .where((element) => !element.fieldInfo.field.isPrimary)
            .mapIndexed(
              (index, cell) => _PropertyCell(
                key: ValueKey('row_detail_${cell.fieldId}'),
                cellContext: cell,
                cellBuilder: cellBuilder,
                index: index,
              ),
            )
            .toList();
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            final reorderedField = children[oldIndex].cellContext.fieldId;
            _reorderField(
              context,
              state.cells,
              reorderedField,
              oldIndex,
              newIndex,
            );
          },
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                child,
                const MouseRegion(cursor: SystemMouseCursors.grabbing),
              ],
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: CreateRowFieldButton(viewId: viewId),
          ),
          children: children,
        );
      },
    );
  }

  void _reorderField(
    BuildContext context,
    List<DatabaseCellContext> cells,
    String reorderedFieldId,
    int oldIndex,
    int newIndex,
  ) {
    // when reorderiing downwards, need to update index
    if (oldIndex < newIndex) {
      newIndex--;
    }

    // also update index when the index is after the index of the primary field
    // in the original list of DatabaseCellContext's
    final primaryFieldIndex =
        cells.indexWhere((element) => element.fieldInfo.isPrimary);
    if (oldIndex >= primaryFieldIndex) {
      oldIndex++;
    }
    if (newIndex >= primaryFieldIndex) {
      newIndex++;
    }

    context.read<RowDetailBloc>().add(
          RowDetailEvent.reorderField(reorderedFieldId, oldIndex, newIndex),
        );
  }
}

class _PropertyCell extends StatefulWidget {
  final DatabaseCellContext cellContext;
  final GridCellBuilder cellBuilder;
  final int index;
  const _PropertyCell({
    required this.cellContext,
    required this.cellBuilder,
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<_PropertyCell> {
  final PopoverController _popoverController = PopoverController();
  bool _isFieldHover = false;

  @override
  Widget build(BuildContext context) {
    final style = _customCellStyle(widget.cellContext.fieldType);
    final cell = widget.cellBuilder.build(widget.cellContext, style: style);

    final dragThumb = MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox(
        width: 16,
        height: 30,
        child: _isFieldHover ? const FlowySvg(FlowySvgs.drag_element_s) : null,
      ),
    );

    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => cell.requestFocus.notify(),
      child: AccessoryHover(child: cell),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(minHeight: 30),
      child: MouseRegion(
        onEnter: (event) => setState(() => _isFieldHover = true),
        onExit: (event) => setState(() => _isFieldHover = false),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: widget.index,
              enabled: _isFieldHover,
              child: dragThumb,
            ),
            const HSpace(4),
            AppFlowyPopover(
              controller: _popoverController,
              constraints: BoxConstraints.loose(const Size(240, 600)),
              margin: EdgeInsets.zero,
              triggerActions: PopoverTriggerFlags.none,
              direction: PopoverDirection.bottomWithLeftAligned,
              popupBuilder: (popoverContext) => buildFieldEditor(),
              child: SizedBox(
                width: 160,
                height: 30,
                child: FieldCellButton(
                  field: widget.cellContext.fieldInfo.field,
                  onTap: () => _popoverController.show(),
                  radius: BorderRadius.circular(6),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                ),
              ),
            ),
            const HSpace(8),
            Expanded(child: gesture),
          ],
        ),
      ),
    );
  }

  Widget buildFieldEditor() {
    return FieldEditor(
      viewId: widget.cellContext.viewId,
      isGroupingField: widget.cellContext.fieldInfo.isGroupField,
      typeOptionLoader: FieldTypeOptionLoader(
        viewId: widget.cellContext.viewId,
        field: widget.cellContext.fieldInfo.field,
      ),
      onHidden: (fieldId) {
        _popoverController.close();
        context.read<RowDetailBloc>().add(RowDetailEvent.hideField(fieldId));
      },
      onDeleted: (fieldId) {
        _popoverController.close();

        NavigatorAlertDialog(
          title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          confirm: () {
            context
                .read<RowDetailBloc>()
                .add(RowDetailEvent.deleteField(fieldId));
          },
        ).show(context);
      },
    );
  }
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
        cellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

class CreateRowFieldButton extends StatefulWidget {
  final String viewId;

  const CreateRowFieldButton({required this.viewId, super.key});

  @override
  State<CreateRowFieldButton> createState() => _CreateRowFieldButtonState();
}

class _CreateRowFieldButtonState extends State<CreateRowFieldButton> {
  late PopoverController popoverController;
  late TypeOptionPB typeOption;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(240, 200)),
      controller: popoverController,
      direction: PopoverDirection.topWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 30,
        child: FlowyButton(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          text: FlowyText.medium(
            LocaleKeys.grid_field_newProperty.tr(),
            color: Theme.of(context).hintColor,
          ),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onTap: () async {
            final result = await TypeOptionBackendService.createFieldTypeOption(
              viewId: widget.viewId,
            );
            result.fold(
              (l) {
                typeOption = l;
                popoverController.show();
              },
              (r) => Log.error("Failed to create field type option: $r"),
            );
          },
          leftIcon: FlowySvg(
            FlowySvgs.add_m,
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
      popupBuilder: (BuildContext popOverContext) {
        return FieldEditor(
          viewId: widget.viewId,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.viewId,
            field: typeOption.field_2,
          ),
          onDeleted: (fieldId) {
            popoverController.close();
            NavigatorAlertDialog(
              title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
              confirm: () {
                context
                    .read<RowDetailBloc>()
                    .add(RowDetailEvent.deleteField(fieldId));
              },
            ).show(context);
          },
        );
      },
    );
  }
}
