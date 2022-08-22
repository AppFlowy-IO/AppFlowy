import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';

import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
// ignore: unused_import
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cell_builder.dart';
import 'extension.dart';
import 'select_option_editor.dart';

class SelectOptionCellStyle extends GridCellStyle {
  String placeholder;

  SelectOptionCellStyle({
    required this.placeholder,
  });
}

class GridSingleSelectCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  late final SelectOptionCellStyle? cellStyle;

  GridSingleSelectCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as SelectOptionCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  State<GridSingleSelectCell> createState() => _SingleSelectCellState();
}

class _SingleSelectCellState extends State<GridSingleSelectCell> {
  late SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridSelectOptionCellController;
    _cellBloc = getIt<SelectOptionCellBloc>(param1: cellController)
      ..add(const SelectOptionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return SelectOptionWrap(
              selectOptions: state.selectedOptions,
              cellStyle: widget.cellStyle,
              onFocus: (value) => widget.onCellEditing.value = value,
              cellControllerBuilder: widget.cellControllerBuilder);
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}

//----------------------------------------------------------------
class GridMultiSelectCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  late final SelectOptionCellStyle? cellStyle;

  GridMultiSelectCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as SelectOptionCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  State<GridMultiSelectCell> createState() => _MultiSelectCellState();
}

class _MultiSelectCellState extends State<GridMultiSelectCell> {
  late SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridSelectOptionCellController;
    _cellBloc = getIt<SelectOptionCellBloc>(param1: cellController)
      ..add(const SelectOptionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return SelectOptionWrap(
            selectOptions: state.selectedOptions,
            cellStyle: widget.cellStyle,
            onFocus: (value) => widget.onCellEditing.value = value,
            cellControllerBuilder: widget.cellControllerBuilder,
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}

class SelectOptionWrap extends StatelessWidget {
  final List<SelectOptionPB> selectOptions;
  final void Function(bool)? onFocus;
  final SelectOptionCellStyle? cellStyle;
  final GridCellControllerBuilder cellControllerBuilder;
  const SelectOptionWrap({
    required this.selectOptions,
    required this.cellControllerBuilder,
    this.onFocus,
    this.cellStyle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final Widget child;
    if (selectOptions.isEmpty && cellStyle != null) {
      child = Align(
        alignment: Alignment.centerLeft,
        child: FlowyText.medium(
          cellStyle!.placeholder,
          fontSize: 14,
          color: theme.shader3,
        ),
      );
    } else {
      child = Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          children: selectOptions
              .map((option) => SelectOptionTag.fromOption(
                    context: context,
                    option: option,
                  ))
              .toList(),
          spacing: 4,
          runSpacing: 2,
        ),
      );
    }

    return Stack(
      alignment: AlignmentDirectional.center,
      fit: StackFit.expand,
      children: [
        child,
        InkWell(onTap: () {
          onFocus?.call(true);
          SelectOptionCellEditor.show(
            context,
            cellControllerBuilder.build() as GridSelectOptionCellController,
            () => onFocus?.call(false),
          );
        }),
      ],
    );
  }
}
