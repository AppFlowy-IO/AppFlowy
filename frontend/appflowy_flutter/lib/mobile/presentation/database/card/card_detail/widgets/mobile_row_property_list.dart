import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileRowPropertyList extends StatelessWidget {
  const MobileRowPropertyList({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.cellBuilder,
  });

  final String viewId;
  final FieldController fieldController;
  final MobileRowDetailPageCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      builder: (context, state) {
        final List<DatabaseCellContext> visibleCells = state.visibleCells
            .where((element) => !element.fieldInfo.field.isPrimary)
            .toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCells.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) => _PropertyCell(
            key: ValueKey('row_detail_${visibleCells[index].fieldId}'),
            cellContext: visibleCells[index],
            fieldController: fieldController,
            cellBuilder: cellBuilder,
          ),
          separatorBuilder: (_, __) => const VSpace(22),
        );
      },
    );
  }
}

class _PropertyCell extends StatefulWidget {
  const _PropertyCell({
    super.key,
    required this.cellContext,
    required this.fieldController,
    required this.cellBuilder,
  });

  final DatabaseCellContext cellContext;
  final FieldController fieldController;
  final MobileRowDetailPageCellBuilder cellBuilder;

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<_PropertyCell> {
  @override
  Widget build(BuildContext context) {
    final style = _customCellStyle(widget.cellContext.fieldType);
    final cell = widget.cellBuilder.build(widget.cellContext, style: style);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            FlowySvg(
              widget.cellContext.fieldInfo.field.fieldType.icon(),
              color: Theme.of(context).hintColor,
            ),
            const HSpace(6),
            Expanded(
              child: FlowyText.regular(
                widget.cellContext.fieldInfo.field.name,
                overflow: TextOverflow.ellipsis,
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const VSpace(6),
        cell,
      ],
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
        cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        useRoundedBorder: true,
      );
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return TimestampCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        alignment: Alignment.centerLeft,
        cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        useRoundedBorder: true,
      );
    case FieldType.MultiSelect:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        useRoundedBorder: true,
      );
    case FieldType.Checklist:
      return ChecklistCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        useRoundedBorders: true,
      );
    case FieldType.Number:
      return GridNumberCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );
    case FieldType.RichText:
      return GridTextCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        useRoundedBorder: true,
      );
    case FieldType.SingleSelect:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        cellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        useRoundedBorder: true,
      );
    case FieldType.URL:
      return GridURLCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
        accessoryTypes: [],
      );
  }
  throw UnimplementedError;
}
