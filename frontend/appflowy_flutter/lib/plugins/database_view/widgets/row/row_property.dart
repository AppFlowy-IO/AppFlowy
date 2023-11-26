import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_cell.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_editor.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
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
  final FieldController fieldController;
  final GridCellBuilder cellBuilder;

  const RowPropertyList({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.cellBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      builder: (context, state) {
        final children = state.visibleCells
            .where((element) => !element.fieldInfo.field.isPrimary)
            .mapIndexed(
              (index, cell) => _PropertyCell(
                key: ValueKey('row_detail_${cell.fieldId}'),
                cellContext: cell,
                cellBuilder: cellBuilder,
                fieldController: fieldController,
                index: index,
              ),
            )
            .toList();

        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            // when reorderiing downwards, need to update index
            if (oldIndex < newIndex) {
              newIndex--;
            }
            final reorderedFieldId = children[oldIndex].cellContext.fieldId;
            final targetFieldId = children[newIndex].cellContext.fieldId;

            context.read<RowDetailBloc>().add(
                  RowDetailEvent.reorderField(
                    reorderedFieldId,
                    targetFieldId,
                    oldIndex,
                    newIndex,
                  ),
                );
          },
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                child,
                MouseRegion(
                  cursor: Platform.isWindows
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.grabbing,
                  child: const SizedBox(
                    width: 16,
                    height: 30,
                    child: FlowySvg(FlowySvgs.drag_element_s),
                  ),
                ),
              ],
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: [
                if (context.read<RowDetailBloc>().state.numHiddenFields != 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: ToggleHiddenFieldsVisibilityButton(),
                  ),
                CreateRowFieldButton(
                  viewId: viewId,
                  fieldController: fieldController,
                ),
              ],
            ),
          ),
          children: children,
        );
      },
    );
  }
}

class _PropertyCell extends StatefulWidget {
  final DatabaseCellContext cellContext;
  final GridCellBuilder cellBuilder;
  final FieldController fieldController;
  final int index;

  const _PropertyCell({
    super.key,
    required this.cellContext,
    required this.cellBuilder,
    required this.fieldController,
    required this.index,
  });

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<_PropertyCell> {
  final PopoverController _popoverController = PopoverController();
  final PopoverController _fieldPopoverController = PopoverController();

  bool _isFieldHover = false;

  @override
  Widget build(BuildContext context) {
    final style = customCellStyle(widget.cellContext.fieldType);
    final cell = widget.cellBuilder.build(widget.cellContext, style: style);

    final dragThumb = MouseRegion(
      cursor: Platform.isWindows
          ? SystemMouseCursors.click
          : SystemMouseCursors.grab,
      child: SizedBox(
        width: 16,
        height: 30,
        child: AppFlowyPopover(
          controller: _fieldPopoverController,
          constraints: BoxConstraints.loose(const Size(240, 600)),
          margin: EdgeInsets.zero,
          triggerActions: PopoverTriggerFlags.none,
          direction: PopoverDirection.bottomWithLeftAligned,
          popupBuilder: (popoverContext) => buildFieldEditor(),
          child: _isFieldHover
              ? BlockActionButton(
                  onTap: () => _fieldPopoverController.show(),
                  svg: FlowySvgs.drag_element_s,
                  richMessage: TextSpan(
                    text: LocaleKeys.grid_rowPage_fieldDragElementTooltip.tr(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );

    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => cell.requestFocus.notify(),
      child: AccessoryHover(
        fieldType: widget.cellContext.fieldType,
        child: cell,
      ),
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
      field: widget.cellContext.fieldInfo.field,
      fieldController: widget.fieldController,
    );
  }
}

GridCellStyle? customCellStyle(FieldType fieldType) {
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
        cellPadding: EdgeInsets.zero,
        showTasksInline: true,
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

class ToggleHiddenFieldsVisibilityButton extends StatelessWidget {
  const ToggleHiddenFieldsVisibilityButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      builder: (context, state) {
        final text = switch (state.showHiddenFields) {
          false => LocaleKeys.grid_rowPage_showHiddenFields
              .plural(state.numHiddenFields),
          true => LocaleKeys.grid_rowPage_hideHiddenFields
              .plural(state.numHiddenFields),
        };

        return SizedBox(
          height: 30,
          child: FlowyButton(
            text: FlowyText.medium(text, color: Theme.of(context).hintColor),
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            leftIcon: RotatedBox(
              quarterTurns: state.showHiddenFields ? 1 : 3,
              child: FlowySvg(
                FlowySvgs.arrow_left_s,
                color: Theme.of(context).hintColor,
              ),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            onTap: () => context.read<RowDetailBloc>().add(
                  const RowDetailEvent.toggleHiddenFieldVisibility(),
                ),
          ),
        );
      },
    );
  }
}

class CreateRowFieldButton extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;

  const CreateRowFieldButton({
    super.key,
    required this.viewId,
    required this.fieldController,
  });

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
      popupBuilder: (BuildContext popoverContext) {
        return FieldEditor(
          viewId: widget.viewId,
          field: typeOption.field_2,
          fieldController: widget.fieldController,
        );
      },
    );
  }
}
