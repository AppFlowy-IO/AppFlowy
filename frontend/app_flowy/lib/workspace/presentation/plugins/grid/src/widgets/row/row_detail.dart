import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/application/grid/row/row_detail_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_cell.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show FieldType;
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_size/window_size.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  final GridRow rowData;
  final GridRowCache rowCache;
  final GridCellCache cellCache;

  const RowDetailPage({
    required this.rowData,
    required this.rowCache,
    required this.cellCache,
    Key? key,
  }) : super(key: key);

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();

  void show(BuildContext context) async {
    final window = await getWindowInfo();
    final size = Size(window.frame.size.width * 0.7, window.frame.size.height * 0.7);
    FlowyOverlay.of(context).insertWithRect(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.tight(size),
      ),
      identifier: RowDetailPage.identifier(),
      anchorPosition: Offset(-size.width / 2.0, -size.height / 2.0),
      anchorSize: window.frame.size,
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
        final bloc = RowDetailBloc(rowData: widget.rowData, rowCache: widget.rowCache);
        bloc.add(const RowDetailEvent.initial());
        return bloc;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
        child: Column(
          children: [
            SizedBox(
                height: 40,
                child: Row(
                  children: const [Spacer(), _CloseButton()],
                )),
            Expanded(child: _PropertyList(cellCache: widget.cellCache)),
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
      onPressed: () => FlowyOverlay.of(context).remove(RowDetailPage.identifier()),
      iconPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      icon: svgWidget("home/close", color: theme.iconColor),
    );
  }
}

class _PropertyList extends StatelessWidget {
  final GridCellCache cellCache;
  final ScrollController _scrollController;
  _PropertyList({
    required this.cellCache,
    Key? key,
  })  : _scrollController = ScrollController(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      buildWhen: (previous, current) => previous.gridCells != current.gridCells,
      builder: (context, state) {
        return ScrollbarListStack(
          axis: Axis.vertical,
          controller: _scrollController,
          barSize: GridSize.scrollBarSize,
          child: ListView.separated(
            controller: _scrollController,
            itemCount: state.gridCells.length,
            itemBuilder: (BuildContext context, int index) {
              return _RowDetailCell(
                gridCell: state.gridCells[index],
                cellCache: cellCache,
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const VSpace(2);
            },
          ),
        );
      },
    );
  }
}

class _RowDetailCell extends StatelessWidget {
  final GridCell gridCell;
  final GridCellCache cellCache;
  const _RowDetailCell({
    required this.gridCell,
    required this.cellCache,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    final cell = buildGridCellWidget(
      gridCell,
      cellCache,
      style: _buildCellStyle(theme, gridCell.field.fieldType),
    );
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: FieldCellButton(field: gridCell.field, onTap: () => _showFieldEditor(context)),
          ),
          const HSpace(10),
          Expanded(
            child: FlowyHover2(
              child: cell,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  void _showFieldEditor(BuildContext context) {
    FieldEditor(
      gridId: gridCell.gridId,
      fieldContextLoader: FieldContextLoaderAdaptor(
        gridId: gridCell.gridId,
        field: gridCell.field,
      ),
    ).show(context);
  }
}

GridCellStyle? _buildCellStyle(AppTheme theme, FieldType fieldType) {
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
    default:
      return null;
  }
}
