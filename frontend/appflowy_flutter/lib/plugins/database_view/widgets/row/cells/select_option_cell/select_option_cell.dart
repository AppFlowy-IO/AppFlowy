import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/mobile_select_option_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
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
  EdgeInsets? cellPadding;
  bool useRoundedBorder;

  SelectOptionCellStyle({
    this.placeholder = "",
    this.cellPadding,
    this.useRoundedBorder = false,
  });
}

class GridSingleSelectCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final SelectOptionCellStyle cellStyle;

  GridSingleSelectCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  }) {
    if (style != null) {
      cellStyle = (style as SelectOptionCellStyle);
    } else {
      cellStyle = SelectOptionCellStyle();
    }
  }

  @override
  GridCellState<GridSingleSelectCell> createState() => _SingleSelectCellState();
}

class _SingleSelectCellState extends GridCellState<GridSingleSelectCell> {
  final PopoverController _popoverController = PopoverController();
  late SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
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
            onCellEditing: (isFocus) =>
                widget.cellContainerNotifier.isFocus = isFocus,
            popoverController: _popoverController,
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
  void requestBeginFocus() => _popoverController.show();
}

//----------------------------------------------------------------
class GridMultiSelectCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final SelectOptionCellStyle cellStyle;

  GridMultiSelectCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  }) {
    if (style != null) {
      cellStyle = (style as SelectOptionCellStyle);
    } else {
      cellStyle = SelectOptionCellStyle();
    }
  }

  @override
  GridCellState<GridMultiSelectCell> createState() => _MultiSelectCellState();
}

class _MultiSelectCellState extends GridCellState<GridMultiSelectCell> {
  final PopoverController _popoverController = PopoverController();
  late SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
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
            onCellEditing: (isFocus) =>
                widget.cellContainerNotifier.isFocus = isFocus,
            popoverController: _popoverController,
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
  void requestBeginFocus() => _popoverController.show();
}

class SelectOptionWrap extends StatefulWidget {
  final List<SelectOptionPB> selectOptions;
  final SelectOptionCellStyle cellStyle;
  final CellControllerBuilder cellControllerBuilder;
  final PopoverController popoverController;
  final void Function(bool) onCellEditing;

  const SelectOptionWrap({
    super.key,
    required this.selectOptions,
    required this.cellControllerBuilder,
    required this.onCellEditing,
    required this.popoverController,
    required this.cellStyle,
  });

  @override
  State<StatefulWidget> createState() => _SelectOptionWrapState();
}

class _SelectOptionWrapState extends State<SelectOptionWrap> {
  @override
  Widget build(BuildContext context) {
    final constraints = BoxConstraints.loose(
      Size(SelectOptionCellEditor.editorPanelWidth, 300),
    );
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;

    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        controller: widget.popoverController,
        constraints: constraints,
        margin: EdgeInsets.zero,
        direction: PopoverDirection.bottomWithLeftAligned,
        popupBuilder: (BuildContext popoverContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCellEditing(true);
          });
          return SelectOptionCellEditor(
            cellController: cellController,
          );
        },
        onClose: () => widget.onCellEditing(false),
        child: Padding(
          padding: widget.cellStyle.cellPadding ?? GridSize.cellContentInsets,
          child: _buildOptions(context),
        ),
      );
    } else if (widget.cellStyle.useRoundedBorder) {
      return InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        onTap: () => showMobileBottomSheet(
          context,
          padding: EdgeInsets.zero,
          builder: (context) {
            return MobileSelectOptionEditor(
              cellController: cellController,
            );
          },
        ),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 48,
            minWidth: double.infinity,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: widget.selectOptions.isEmpty ? 13 : 10,
          ),
          decoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildMobileOptions(isInRowDetail: true)),
              const HSpace(6),
              RotatedBox(
                quarterTurns: 3,
                child: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const HSpace(2),
            ],
          ),
        ),
      );
    } else {
      return FlowyButton(
        hoverColor: Colors.transparent,
        radius: BorderRadius.zero,
        text: Padding(
          padding: widget.cellStyle.cellPadding ?? GridSize.cellContentInsets,
          child: _buildMobileOptions(isInRowDetail: false),
        ),
        onTap: () {
          showMobileBottomSheet(
            context,
            padding: EdgeInsets.zero,
            builder: (context) {
              return MobileSelectOptionEditor(
                cellController: cellController,
              );
            },
          );
        },
      );
    }
  }

  Widget _buildOptions(BuildContext context) {
    final Widget child;
    if (widget.selectOptions.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: FlowyText.medium(
          widget.cellStyle.placeholder,
          color: Theme.of(context).hintColor,
        ),
      );
    } else {
      final children = widget.selectOptions.map(
        (option) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SelectOptionTag(
              option: option,
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
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

  Widget _buildMobileOptions({required bool isInRowDetail}) {
    if (widget.selectOptions.isEmpty) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: FlowyText(
          widget.cellStyle.placeholder,
          color: Theme.of(context).hintColor,
        ),
      );
    } else {
      final children = widget.selectOptions.mapIndexed(
        (index, option) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
            child: SelectOptionTag(
              option: option,
              fontSize: 14,
              padding: isInRowDetail
                  ? const EdgeInsets.symmetric(horizontal: 11, vertical: 5)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        },
      ).toList();

      return Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          runSpacing: 4,
          children: children,
        ),
      );
    }
  }
}
