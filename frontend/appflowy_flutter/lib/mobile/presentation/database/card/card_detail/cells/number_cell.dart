import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/number_cell/number_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowDetailNumberCell extends GridCellWidget {
  RowDetailNumberCell({
    super.key,
    required this.cellControllerBuilder,
    this.hintText,
  });

  final CellControllerBuilder cellControllerBuilder;
  final String? hintText;

  @override
  GridEditableTextCell<RowDetailNumberCell> createState() =>
      _RowDetailNumberCellState();
}

class _RowDetailNumberCellState
    extends GridEditableTextCell<RowDetailNumberCell> {
  late final NumberCellBloc _cellBloc;
  late final TextEditingController _controller;

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as NumberCellController;
    _cellBloc = NumberCellBloc(cellController: cellController)
      ..add(const NumberCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.cellContent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<NumberCellBloc, NumberCellState>(
            listenWhen: (p, c) => p.cellContent != c.cellContent,
            listener: (context, state) => _controller.text = state.cellContent,
          ),
        ],
        child: TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          focusNode: focusNode,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
          decoration: InputDecoration(
            enabledBorder:
                _getInputBorder(color: Theme.of(context).colorScheme.outline),
            focusedBorder:
                _getInputBorder(color: Theme.of(context).colorScheme.primary),
            hintText: widget.hintText,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isCollapsed: true,
            isDense: true,
            constraints: const BoxConstraints(),
          ),
          // close keyboard when tapping outside of the text field
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ),
    );
  }

  InputBorder _getInputBorder({Color? color}) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color!),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      gapPadding: 0,
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  Future<void> focusChanged() async {
    if (mounted &&
        !_cellBloc.isClosed &&
        _controller.text != _cellBloc.state.cellContent) {
      _cellBloc.add(NumberCellEvent.updateCell(_controller.text));
    }
  }

  @override
  String? onCopy() => _cellBloc.state.cellContent;
}
