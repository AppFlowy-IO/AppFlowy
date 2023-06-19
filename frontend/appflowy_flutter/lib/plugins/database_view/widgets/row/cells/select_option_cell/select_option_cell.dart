import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';
import 'extension.dart';
import 'select_option_cell_bloc.dart';
import 'select_option_editor.dart';

class SelectOptionCellStyle extends GridCellStyle {
  String placeholder;

  SelectOptionCellStyle({
    required this.placeholder,
  });
}

class GridSingleSelectCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
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
  GridCellState<GridSingleSelectCell> createState() => _SingleSelectCellState();
}

class _SingleSelectCellState extends GridCellState<GridSingleSelectCell> {
  late SelectOptionCellBloc _cellBloc;
  late final PopoverController _popover;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
    _popover = PopoverController();
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
            onCellEditing: widget.onCellEditing,
            popoverController: _popover,
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

  @override
  void requestBeginFocus() => _popover.show();
}

//----------------------------------------------------------------
class GridMultiSelectCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
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
  GridCellState<GridMultiSelectCell> createState() => _MultiSelectCellState();
}

class _MultiSelectCellState extends GridCellState<GridMultiSelectCell> {
  late SelectOptionCellBloc _cellBloc;
  late final PopoverController _popover;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
    _popover = PopoverController();
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
            onCellEditing: widget.onCellEditing,
            popoverController: _popover,
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

  @override
  void requestBeginFocus() => _popover.show();
}

class SelectOptionWrap extends StatefulWidget {
  final List<SelectOptionPB> selectOptions;
  final SelectOptionCellStyle? cellStyle;
  final CellControllerBuilder cellControllerBuilder;
  final PopoverController popoverController;
  final ValueNotifier onCellEditing;

  const SelectOptionWrap({
    required this.selectOptions,
    required this.cellControllerBuilder,
    required this.onCellEditing,
    required this.popoverController,
    this.cellStyle,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SelectOptionWrapState();
}

class _SelectOptionWrapState extends State<SelectOptionWrap> {
  @override
  Widget build(BuildContext context) {
    final Widget child = _buildOptions(context);

    final constraints = BoxConstraints.loose(
      Size(
        SelectOptionCellEditor.editorPanelWidth,
        300,
      ),
    );
    return AppFlowyPopover(
      controller: widget.popoverController,
      constraints: constraints,
      margin: EdgeInsets.zero,
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCellEditing.value = true;
        });
        return SelectOptionCellEditor(
          cellController: widget.cellControllerBuilder.build()
              as SelectOptionCellController,
        );
      },
      onClose: () => widget.onCellEditing.value = false,
      child: Padding(
        padding: GridSize.cellContentInsets,
        child: child,
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
    final Widget child;
    if (widget.selectOptions.isEmpty && widget.cellStyle != null) {
      child = FlowyText.medium(
        widget.cellStyle!.placeholder,
        color: Theme.of(context).hintColor,
      );
    } else {
      final children = widget.selectOptions.map(
        (option) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SelectOptionTag.fromOption(
              context: context,
              option: option,
            ),
          );
        },
      ).toList();

      child = Wrap(
        runSpacing: 4,
        children: children,
      );
    }
    return Align(alignment: Alignment.centerLeft, child: child);
  }
}
