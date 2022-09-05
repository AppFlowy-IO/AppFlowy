import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_detail_bloc.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';
import '../cell/cell_accessory.dart';
import '../cell/prelude.dart';
import '../header/field_cell.dart';
import '../header/field_editor.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  final GridRowDataController dataController;
  final GridCellBuilder cellBuilder;

  const RowDetailPage({
    required this.dataController,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();

  void show(BuildContext context) async {
    final windowSize = MediaQuery.of(context).size;
    final size = windowSize * 0.5;
    FlowyOverlay.of(context).insertWithRect(
      widget: OverlayContainer(
        constraints: BoxConstraints.tight(size),
        child: this,
      ),
      identifier: RowDetailPage.identifier(),
      anchorPosition: Offset(-size.width / 2.0, -size.height / 2.0),
      anchorSize: windowSize,
      anchorDirection: AnchorDirection.center,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  static String identifier() {
    return (RowDetailPage).toString();
  }
}

class _RowDetailPageState extends State<RowDetailPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = RowDetailBloc(
          dataController: widget.dataController,
        );
        bloc.add(const RowDetailEvent.initial());
        return bloc;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            SizedBox(
              height: 30,
              child: Row(
                children: const [Spacer(), _CloseButton()],
              ),
            ),
            Expanded(
              child: _PropertyList(
                cellBuilder: widget.cellBuilder,
                viewId: widget.dataController.rowInfo.gridId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      width: 24,
      onPressed: () =>
          FlowyOverlay.of(context).remove(RowDetailPage.identifier()),
      iconPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      icon: svgWidget("home/close", color: theme.iconColor),
    );
  }
}

class _PropertyList extends StatelessWidget {
  final String viewId;
  final GridCellBuilder cellBuilder;
  final ScrollController _scrollController;
  _PropertyList({
    required this.viewId,
    required this.cellBuilder,
    Key? key,
  })  : _scrollController = ScrollController(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      buildWhen: (previous, current) => previous.gridCells != current.gridCells,
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: ScrollbarListStack(
                axis: Axis.vertical,
                controller: _scrollController,
                barSize: GridSize.scrollBarSize,
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: state.gridCells.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _RowDetailCell(
                      cellId: state.gridCells[index],
                      cellBuilder: cellBuilder,
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const VSpace(2);
                  },
                ),
              ),
            ),
            _CreateFieldButton(viewId: viewId),
          ],
        );
      },
    );
  }
}

class _CreateFieldButton extends StatelessWidget {
  final String viewId;
  const _CreateFieldButton({required this.viewId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppTheme>();

    return SizedBox(
      height: 40,
      child: FlowyButton(
        text: FlowyText.medium(
          LocaleKeys.grid_field_newColumn.tr(),
          fontSize: 12,
        ),
        hoverColor: theme.shader6,
        onTap: () => FieldEditor(
          gridId: viewId,
          fieldName: "",
          typeOptionLoader: NewFieldTypeOptionLoader(gridId: viewId),
        ).show(context),
        leftIcon: svgWidget("home/add"),
      ),
    );
  }
}

class _RowDetailCell extends StatelessWidget {
  final GridCellIdentifier cellId;
  final GridCellBuilder cellBuilder;
  const _RowDetailCell({
    required this.cellId,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final style = _customCellStyle(theme, cellId.fieldType);
    final cell = cellBuilder.build(cellId, style: style);

    final gesture = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => cell.beginFocus.notify(),
      child: AccessoryHover(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: cell,
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: FieldCellButton(
                field: cellId.fieldContext.field,
                onTap: () => _showFieldEditor(context),
              ),
            ),
            const HSpace(10),
            Expanded(child: gesture),
          ],
        ),
      ),
    );
  }

  void _showFieldEditor(BuildContext context) {
    FieldEditor(
      gridId: cellId.gridId,
      fieldName: cellId.fieldContext.name,
      typeOptionLoader: FieldTypeOptionLoader(
        gridId: cellId.gridId,
        field: cellId.fieldContext.field,
      ),
    ).show(context);
  }
}

GridCellStyle? _customCellStyle(AppTheme theme, FieldType fieldType) {
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
          GridURLCellAccessoryType.edit,
          GridURLCellAccessoryType.copyURL,
        ],
      );
  }
  throw UnimplementedError;
}
