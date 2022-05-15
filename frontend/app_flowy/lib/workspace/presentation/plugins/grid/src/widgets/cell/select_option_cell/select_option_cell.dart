import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/cell_builder.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
// ignore: unused_import
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'extension.dart';
import 'select_option_editor.dart';

class SelectOptionCellStyle extends GridCellStyle {
  String placeholder;

  SelectOptionCellStyle({
    required this.placeholder,
  });
}

class SingleSelectCell extends GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;
  late final SelectOptionCellStyle? cellStyle;

  SingleSelectCell({
    required this.cellContextBuilder,
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
  State<SingleSelectCell> createState() => _SingleSelectCellState();
}

class _SingleSelectCellState extends State<SingleSelectCell> {
  late SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build() as GridSelectOptionCellContext;
    _cellBloc = getIt<SelectOptionCellBloc>(param1: cellContext)..add(const SelectOptionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return _SelectOptionCell(
              selectOptions: state.selectedOptions,
              cellStyle: widget.cellStyle,
              onFocus: (value) => widget.onFocus.value = value,
              cellContextBuilder: widget.cellContextBuilder);
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
class MultiSelectCell extends GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;
  late final SelectOptionCellStyle? cellStyle;

  MultiSelectCell({
    required this.cellContextBuilder,
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
  State<MultiSelectCell> createState() => _MultiSelectCellState();
}

class _MultiSelectCellState extends State<MultiSelectCell> {
  late SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build() as GridSelectOptionCellContext;
    _cellBloc = getIt<SelectOptionCellBloc>(param1: cellContext)..add(const SelectOptionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return _SelectOptionCell(
              selectOptions: state.selectedOptions,
              cellStyle: widget.cellStyle,
              onFocus: (value) => widget.onFocus.value = value,
              cellContextBuilder: widget.cellContextBuilder);
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

class _SelectOptionCell extends StatelessWidget {
  final List<SelectOption> selectOptions;
  final void Function(bool) onFocus;
  final SelectOptionCellStyle? cellStyle;
  final GridCellContextBuilder cellContextBuilder;
  const _SelectOptionCell({
    required this.selectOptions,
    required this.onFocus,
    required this.cellStyle,
    required this.cellContextBuilder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final Widget child;
    if (selectOptions.isEmpty && cellStyle != null) {
      child = Align(
        alignment: Alignment.centerLeft,
        child: FlowyText.medium(cellStyle!.placeholder, fontSize: 14, color: theme.shader3),
      );
    } else {
      final tags = selectOptions
          .map(
            (option) => SelectOptionTag.fromSelectOption(
              context: context,
              option: option,
            ),
          )
          .toList();
      child = Align(
        alignment: Alignment.centerLeft,
        child: Wrap(children: tags, spacing: 4, runSpacing: 4),
      );
    }

    return Stack(
      alignment: AlignmentDirectional.center,
      fit: StackFit.expand,
      children: [
        child,
        InkWell(
          onTap: () {
            onFocus(true);
            final cellContext = cellContextBuilder.build() as GridSelectOptionCellContext;
            SelectOptionCellEditor.show(context, cellContext, () => onFocus(false));
          },
        ),
      ],
    );
  }
}
