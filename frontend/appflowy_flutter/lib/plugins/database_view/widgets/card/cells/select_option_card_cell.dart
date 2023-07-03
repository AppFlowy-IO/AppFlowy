import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/select_option_card_cell_bloc.dart';
import 'card_cell.dart';

class SelectOptionCardCellStyle extends CardCellStyle {}

class SelectOptionCardCell<CustomCardData>
    extends CardCell<CustomCardData, SelectOptionCardCellStyle>
    with EditableCell {
  final CellControllerBuilder cellControllerBuilder;
  final CellRenderHook<List<SelectOptionPB>, CustomCardData>? renderHook;

  @override
  final EditableCardNotifier? editableNotifier;

  SelectOptionCardCell({
    required this.cellControllerBuilder,
    required CustomCardData? cardData,
    this.renderHook,
    this.editableNotifier,
    Key? key,
  }) : super(key: key, cardData: cardData);

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
        },
        builder: (context, state) {
          final Widget? custom = widget.renderHook?.call(
            state.selectedOptions,
            widget.cardData,
            context,
          );
          if (custom != null) {
            return custom;
          }

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
        },
      ),
    );
  }

  Widget _wrapPopover(Widget child) {
    final constraints = BoxConstraints.loose(
      Size(
        SelectOptionCellEditor.editorPanelWidth,
        300,
      ),
    );
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
