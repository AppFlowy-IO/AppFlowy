import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import '../../grid/presentation/layout/sizes.dart';
import 'accessory/cell_accessory.dart';
import 'cell_builder.dart';
import 'cells/date_cell/date_cell.dart';
import 'cells/select_option_cell/select_option_cell.dart';
import 'cells/text_cell/text_cell.dart';
import 'cells/url_cell/url_cell.dart';
import '../../grid/presentation/widgets/header/field_cell.dart';
import '../../grid/presentation/widgets/header/field_editor.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  final RowController dataController;
  final GridCellBuilder cellBuilder;

  const RowDetailPage({
    required this.dataController,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();

  static String identifier() {
    return (RowDetailPage).toString();
  }
}

class _RowDetailPageState extends State<RowDetailPage> {
  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      child: BlocProvider(
        create: (context) {
          return RowDetailBloc(dataController: widget.dataController)
            ..add(const RowDetailEvent.initial());
        },
        child: ListView(
          children: [
            // using ListView here for future expansion:
            // - header and cover image
            // - lower rich text area
            IntrinsicHeight(child: _responsiveRowInfo()),
            const Divider(height: 1.0),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _responsiveRowInfo() {
    final rowDataColumn = _PropertyColumn(
      cellBuilder: widget.cellBuilder,
      viewId: widget.dataController.viewId,
    );
    final rowOptionColumn = _RowOptionColumn(
      viewId: widget.dataController.viewId,
      rowId: widget.dataController.rowId,
    );
    if (MediaQuery.of(context).size.width > 800) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(50, 50, 20, 20),
              child: rowDataColumn,
            ),
          ),
          const VerticalDivider(width: 1.0),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: rowOptionColumn,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: rowDataColumn,
          ),
          const Divider(height: 1.0),
          Padding(
            padding: const EdgeInsets.all(20),
            child: rowOptionColumn,
          )
        ],
      );
    }
  }
}

class _PropertyColumn extends StatelessWidget {
  final String viewId;
  final GridCellBuilder cellBuilder;
  const _PropertyColumn({
    required this.viewId,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      buildWhen: (previous, current) => previous.gridCells != current.gridCells,
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RowTitle(
              cellId: state.gridCells
                  .firstWhereOrNull((e) => e.fieldInfo.isPrimary),
              cellBuilder: cellBuilder,
            ),
            const VSpace(20),
            ...state.gridCells
                .where((element) => !element.fieldInfo.isPrimary)
                .map(
                  (cell) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: _PropertyCell(
                      cellId: cell,
                      cellBuilder: cellBuilder,
                    ),
                  ),
                )
                .toList(),
            const VSpace(20),
            _CreatePropertyButton(viewId: viewId),
          ],
        );
      },
    );
  }
}

class _RowTitle extends StatelessWidget {
  final CellIdentifier? cellId;
  final GridCellBuilder cellBuilder;
  const _RowTitle({this.cellId, required this.cellBuilder, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cellId == null) {
      return const SizedBox();
    }
    final style = GridTextCellStyle(
      placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      textStyle: Theme.of(context).textTheme.titleLarge,
      autofocus: true,
    );
    return cellBuilder.build(cellId!, style: style);
  }
}

class _CreatePropertyButton extends StatefulWidget {
  final String viewId;

  const _CreatePropertyButton({
    required this.viewId,
    Key? key,
  }) : super(key: key);

  @override
  State<_CreatePropertyButton> createState() => _CreatePropertyButtonState();
}

class _CreatePropertyButtonState extends State<_CreatePropertyButton> {
  late PopoverController popoverController;

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
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 40,
        child: FlowyButton(
          text: FlowyText.medium(
            LocaleKeys.grid_field_newProperty.tr(),
            color: AFThemeExtension.of(context).textColor,
          ),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onTap: () {},
          leftIcon: svgWidget(
            "home/add",
            color: AFThemeExtension.of(context).textColor,
          ),
        ),
      ),
      popupBuilder: (BuildContext popOverContext) {
        return FieldEditor(
          viewId: widget.viewId,
          typeOptionLoader: NewFieldTypeOptionLoader(viewId: widget.viewId),
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

class _PropertyCell extends StatefulWidget {
  final CellIdentifier cellId;
  final GridCellBuilder cellBuilder;
  const _PropertyCell({
    required this.cellId,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<_PropertyCell> {
  final PopoverController popover = PopoverController();

  @override
  Widget build(BuildContext context) {
    final style = _customCellStyle(widget.cellId.fieldType);
    final cell = widget.cellBuilder.build(widget.cellId, style: style);

    final gesture = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => cell.beginFocus.notify(),
      child: AccessoryHover(
        contentPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: cell,
      ),
    );

    return IntrinsicHeight(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppFlowyPopover(
              controller: popover,
              constraints: BoxConstraints.loose(const Size(240, 600)),
              margin: EdgeInsets.zero,
              triggerActions: PopoverTriggerFlags.none,
              popupBuilder: (popoverContext) => buildFieldEditor(),
              child: SizedBox(
                width: 150,
                child: FieldCellButton(
                  field: widget.cellId.fieldInfo.field,
                  onTap: () => popover.show(),
                  radius: BorderRadius.circular(6),
                ),
              ),
            ),
            const HSpace(10),
            Expanded(child: gesture),
          ],
        ),
      ),
    );
  }

  Widget buildFieldEditor() {
    return FieldEditor(
      viewId: widget.cellId.viewId,
      fieldName: widget.cellId.fieldInfo.field.name,
      isGroupField: widget.cellId.fieldInfo.isGroupField,
      typeOptionLoader: FieldTypeOptionLoader(
        viewId: widget.cellId.viewId,
        field: widget.cellId.fieldInfo.field,
      ),
      onDeleted: (fieldId) {
        popover.close();

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
      return null;
    case FieldType.DateTime:
      return DateCellStyle(
        alignment: Alignment.centerLeft,
      );
    case FieldType.MultiSelect:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );
    case FieldType.Checklist:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );
    case FieldType.Number:
      return null;
    case FieldType.RichText:
      return GridTextCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
      );
    case FieldType.SingleSelect:
      return SelectOptionCellStyle(
        placeholder: LocaleKeys.grid_row_textPlaceholder.tr(),
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

class _RowOptionColumn extends StatelessWidget {
  final String rowId;
  const _RowOptionColumn({
    required String viewId,
    required this.rowId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: FlowyText(LocaleKeys.grid_row_action.tr()),
        ),
        const VSpace(15),
        _DeleteButton(rowId: rowId),
        _DuplicateButton(rowId: rowId),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final String rowId;
  const _DeleteButton({required this.rowId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_delete.tr()),
        leftIcon: const FlowySvg(name: "home/trash"),
        onTap: () {
          context.read<RowDetailBloc>().add(RowDetailEvent.deleteRow(rowId));
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

class _DuplicateButton extends StatelessWidget {
  final String rowId;
  const _DuplicateButton({required this.rowId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_duplicate.tr()),
        leftIcon: const FlowySvg(name: "grid/duplicate"),
        onTap: () {
          context.read<RowDetailBloc>().add(RowDetailEvent.duplicateRow(rowId));
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}
