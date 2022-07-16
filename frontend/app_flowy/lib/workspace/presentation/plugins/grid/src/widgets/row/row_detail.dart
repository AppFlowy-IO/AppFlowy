import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/application/grid/row/row_detail_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/cell_accessory.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/url_cell/url_cell.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_cell.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowDetailPage extends StatefulWidget with FlowyOverlayDelegate {
  final GridRow rowData;
  final GridRowCache rowCache;
  final GridCellBuilder cellBuilder;

  const RowDetailPage({
    required this.rowData,
    required this.rowCache,
    required this.cellBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<RowDetailPage> createState() => _RowDetailPageState();

  void show(BuildContext context) async {
    final windowSize = MediaQuery.of(context).size;
    final size = windowSize * 0.7;
    FlowyOverlay.of(context).insertWithRect(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.tight(size),
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
        final bloc = RowDetailBloc(rowData: widget.rowData, rowCache: widget.rowCache);
        bloc.add(const RowDetailEvent.initial());
        return bloc;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: const [Spacer(), _CloseButton()],
              ),
            ),
            Expanded(child: _PropertyList(cellBuilder: widget.cellBuilder)),
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
  final GridCellBuilder cellBuilder;
  final ScrollController _scrollController;
  _PropertyList({
    required this.cellBuilder,
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
                cellId: state.gridCells[index],
                cellBuilder: cellBuilder,
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
        child: cell,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              child: FieldCellButton(field: cellId.field, onTap: () => _showFieldEditor(context)),
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
      fieldName: cellId.field.name,
      contextLoader: FieldTypeOptionLoader(
        gridId: cellId.gridId,
        field: cellId.field,
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
