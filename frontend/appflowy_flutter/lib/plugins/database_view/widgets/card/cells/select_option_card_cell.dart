import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/cell/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/cell/select_option_cell/select_option_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/select_option_card_cell_bloc.dart';
import 'card_cell.dart';

class SelectOptionCardCell extends CardCell with EditableCell {
  final String groupId;
  final CellControllerBuilder cellControllerBuilder;
  @override
  final EditableCardNotifier? editableNotifier;

  const SelectOptionCardCell({
    required this.groupId,
    required this.cellControllerBuilder,
    this.editableNotifier,
    Key? key,
  }) : super(key: key);

  @override
  State<SelectOptionCardCell> createState() => _SelectOptionCardCellState();
}

class _SelectOptionCardCellState extends State<SelectOptionCardCell> {
  late SelectOptionCardCellBloc _cellBloc;
  late PopoverController _popover;

  @override
  void initState() {
    _popover = PopoverController();
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCardCellBloc(cellController: cellController)
      ..add(const SelectOptionCardCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCardCellBloc, SelectOptionCardCellState>(
          buildWhen: (previous, current) {
        return previous.selectedOptions != current.selectedOptions;
      }, builder: (context, state) {
        // Returns SizedBox if the content of the cell is empty
        if (_isEmpty(state)) return const SizedBox();

        final children = state.selectedOptions.map(
          (option) {
            final tag = SelectOptionTag.fromOption(
              context: context,
              option: option,
              onSelected: () => _popover.show(),
            );
            return _wrapPopover(tag);
          },
        ).toList();

        return IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox.expand(
              child: Wrap(spacing: 4, runSpacing: 2, children: children),
            ),
          ),
        );
      }),
    );
  }

  bool _isEmpty(SelectOptionCardCellState state) {
    // The cell should hide if the option id is equal to the groupId.
    final isInGroup = state.selectedOptions
        .where((element) => element.id == widget.groupId)
        .isNotEmpty;
    return isInGroup || state.selectedOptions.isEmpty;
  }

  Widget _wrapPopover(Widget child) {
    final constraints = BoxConstraints.loose(Size(
      SelectOptionCellEditor.editorPanelWidth,
      300,
    ));
    return AppFlowyPopover(
      controller: _popover,
      constraints: constraints,
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (BuildContext context) {
        return SelectOptionCellEditor(
          cellController: widget.cellControllerBuilder.build()
              as SelectOptionCellController,
        );
      },
      onClose: () {},
      child: child,
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}
