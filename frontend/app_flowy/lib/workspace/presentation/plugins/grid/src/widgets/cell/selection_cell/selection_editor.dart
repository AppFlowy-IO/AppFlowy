import 'package:app_flowy/workspace/application/grid/cell_bloc/selection_editor_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'selection.dart';

class SelectionEditor extends StatelessWidget {
  final GridCellData cellData;
  const SelectionEditor({required this.cellData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectionEditorBloc(gridId: cellData.gridId, field: cellData.field),
      child: BlocBuilder<SelectionEditorBloc, SelectionEditorState>(
        builder: (context, state) {
          return Container();
        },
      ),
    );
  }
}

class _SelectionCell extends StatelessWidget {
  final SelectOption option;
  const _SelectionCell({required this.option, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return InkWell(
      onTap: () {},
      child: FlowyHover(
        config: HoverDisplayConfig(hoverColor: theme.hover),
        builder: (_, onHover) {
          return SelectionBadge(option: option);
        },
      ),
    );
  }
}
