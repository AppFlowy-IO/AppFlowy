import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/mobile_create_row_field_button.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/card_property_edit_screen.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_property.dart';

import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Display the row properties in a list. Only use this widget in the
/// [MobileCardDetailScreen].
class MobileRowPropertyList extends StatelessWidget {
  const MobileRowPropertyList({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.cellBuilder,
  });

  final String viewId;
  final FieldController fieldController;
  final GridCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      builder: (context, state) {
        final List<DatabaseCellContext> visibleCells = state.visibleCells
            .where((element) => !element.fieldInfo.field.isPrimary)
            .toList();

        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCells.length,
          itemBuilder: (context, index) => _PropertyCell(
            key: ValueKey('row_detail_${visibleCells[index].fieldId}'),
            cellContext: visibleCells[index],
            fieldController: fieldController,
            cellBuilder: cellBuilder,
            index: index,
          ),
          onReorder: (oldIndex, newIndex) {
            // when reorderiing downwards, need to update index
            if (oldIndex < newIndex) {
              newIndex--;
            }
            final reorderedFieldId = visibleCells[oldIndex].fieldId;
            final targetFieldId = visibleCells[newIndex].fieldId;

            context.read<RowDetailBloc>().add(
                  RowDetailEvent.reorderField(
                    reorderedFieldId,
                    targetFieldId,
                    oldIndex,
                    newIndex,
                  ),
                );
          },
          footer: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (context.read<RowDetailBloc>().state.numHiddenFields != 0)
                  const ToggleHiddenFieldsVisibilityButton(),
                const VSpace(8),
                // add new field
                MobileCreateRowFieldButton(
                  viewId: viewId,
                  fieldController: fieldController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// TODO(yijing): temperary locate here
// It may need to be share with other widgets
const cellHeight = 32.0;

class _PropertyCell extends StatefulWidget {
  const _PropertyCell({
    super.key,
    required this.cellContext,
    required this.fieldController,
    required this.cellBuilder,
    required this.index,
  });

  final DatabaseCellContext cellContext;
  final FieldController fieldController;
  final GridCellBuilder cellBuilder;
  final int index;

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<_PropertyCell> {
  @override
  Widget build(BuildContext context) {
    final style = _customCellStyle(widget.cellContext.fieldType);
    final cell = widget.cellBuilder.build(widget.cellContext, style: style);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: 4,
      // FieldCellButton in Desktop
      // TODO(yijing): adjust width with sreen size
      leading: SizedBox(
        width: 150,
        height: cellHeight,
        child: TextButton.icon(
          icon: FlowySvg(
            widget.cellContext.fieldInfo.field.fieldType.icon(),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          label: Text(
            widget.cellContext.fieldInfo.field.name,
            // TODO(yijing): update text style
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
          ),
          // naivgator to field editor
          onPressed: () => context.push(
            CardPropertyEditScreen.routeName,
            extra: {
              CardPropertyEditScreen.argCellContext: widget.cellContext,
              CardPropertyEditScreen.argFieldController: widget.fieldController,
              CardPropertyEditScreen.argRowDetailBloc:
                  context.read<RowDetailBloc>(),
            },
          ),
        ),
      ),
      title: SizedBox(
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
