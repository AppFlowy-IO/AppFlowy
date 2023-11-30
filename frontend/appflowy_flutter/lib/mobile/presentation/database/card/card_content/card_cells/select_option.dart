import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_content/card_cells/style.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileSelectOptionCardCell<CustomCardData> extends CardCell {
  const MobileSelectOptionCardCell({
    super.key,
    required this.cellControllerBuilder,
    required CustomCardData? cardData,
    this.renderHook,
  });

  final CellControllerBuilder cellControllerBuilder;
  final CellRenderHook<List<SelectOptionPB>, CustomCardData>? renderHook;

  @override
  State<MobileSelectOptionCardCell> createState() => _SelectOptionCellState();
}

class _SelectOptionCellState extends State<MobileSelectOptionCardCell> {
  late final SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellStyle = MobileCardCellStyle(context);
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
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

          final children = state.selectedOptions
              .map(
                (option) => MobileSelectOptionTag.fromOption(
                  context: context,
                  option: option,
                ),
              )
              .toList();

          return IntrinsicHeight(
            child: Padding(
              padding: cellStyle.padding,
              child: SizedBox.expand(
                child: Wrap(spacing: 4, runSpacing: 2, children: children),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MobileSelectOptionTag extends StatelessWidget {
  const MobileSelectOptionTag({
    super.key,
    required this.name,
    required this.color,
    this.onSelected,
    this.onRemove,
  });

  factory MobileSelectOptionTag.fromOption({
    required BuildContext context,
    required SelectOptionPB option,
    VoidCallback? onSelected,
    Function(String)? onRemove,
  }) {
    return MobileSelectOptionTag(
      name: option.name,
      color: option.color.toColor(context),
      onSelected: onSelected,
      onRemove: onRemove,
    );
  }

  final String name;
  final Color color;
  final VoidCallback? onSelected;
  final void Function(String)? onRemove;

  @override
  Widget build(BuildContext context) {
    final cellStyle = MobileCardCellStyle(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              style: cellStyle.tagTextStyle(),
            ),
          ),
          if (onRemove != null) ...[
            const HSpace(2),
            IconButton(
              onPressed: () => onRemove?.call(name),
              icon: const FlowySvg(
                FlowySvgs.close_s,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
