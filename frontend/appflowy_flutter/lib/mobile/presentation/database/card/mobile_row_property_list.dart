import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit_screen.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_editor.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_property.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../plugins/database_view/widgets/row/accessory/cell_accessory.dart';
import '../../../../plugins/database_view/widgets/row/cell_builder.dart';

/// Display the row properties in a list. Only use this widget in the
/// [MobileCardDetailScreen].
class MobileRowPropertyList extends StatelessWidget {
  final String viewId;
  final GridCellBuilder cellBuilder;
  const MobileRowPropertyList({
    required this.viewId,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

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
          // add new field
          footer: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                if (context.read<RowDetailBloc>().state.numHiddenFields != 0)
                  const ToggleHiddenFieldsVisibilityButton(),
                const VSpace(8),
                CreateRowFieldButton(viewId: viewId),
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

  @override
  Widget build(BuildContext context) {
    const cellHeight = 32.0;
    final style = _customCellStyle(widget.cellContext.fieldType);
    final cell = widget.cellBuilder.build(widget.cellContext, style: style);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: 4,
      // FieldCellButton in Desktop
      leading: SizedBox(
        width: 120,
        height: cellHeight,
        child: TextButton.icon(
          icon: FlowySvg(
            widget.cellContext.fieldInfo.field.fieldType.icon(),
          ),
          label: Text(
            widget.cellContext.fieldInfo.field.name,
            // TODO(yijing): update text style
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
          ),
          // naivgator to field editor
          onPressed: () => context.push(
            CardPropertyEditScreen.routeName,
            extra: {
              CardPropertyEditScreen.argCellContext: widget.cellContext,
              CardPropertyEditScreen.argRowDetailBloc:
                  context.read<RowDetailBloc>(),
            },
          ),
        ),
      ),
      title: SizedBox(
        height: cellHeight,
        width: double.infinity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => cell.requestFocus.notify(),
          //property values
          child: AccessoryHover(
            fieldType: widget.cellContext.fieldType,
            child: cell,
          ),
        ),
      ),
    );
  }

  Widget buildFieldEditor() {
    return FieldEditor(
      viewId: widget.cellContext.viewId,
      fieldInfo: widget.cellContext.fieldInfo,
      isGroupingField: widget.cellContext.fieldInfo.isGroupField,
      typeOptionLoader: FieldTypeOptionLoader(
        viewId: widget.cellContext.viewId,
        field: widget.cellContext.fieldInfo.field,
      ),
      onToggleVisibility: (fieldId) {
        _popoverController.close();
        context
            .read<RowDetailBloc>()
            .add(RowDetailEvent.toggleFieldVisibility(fieldId));
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
