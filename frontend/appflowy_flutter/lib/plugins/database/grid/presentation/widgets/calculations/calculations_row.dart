import 'package:appflowy/plugins/database/grid/application/calculations/calculations_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculate_cell.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridCalculationsRow extends StatelessWidget {
  const GridCalculationsRow({
    super.key,
    required this.viewId,
    this.includeDefaultInsets = true,
  });

  final String viewId;
  final bool includeDefaultInsets;

  @override
  Widget build(BuildContext context) {
    final gridBloc = context.read<GridBloc>();

    return BlocProvider(
      create: (context) => CalculationsBloc(
        viewId: gridBloc.databaseController.viewId,
        fieldController: gridBloc.databaseController.fieldController,
      )..add(const CalculationsEvent.started()),
      child: BlocBuilder<CalculationsBloc, CalculationsState>(
        builder: (context, state) {
          final padding =
              context.read<DatabasePluginWidgetBuilderSize>().horizontalPadding;
          return Padding(
            padding: includeDefaultInsets
                ? EdgeInsets.symmetric(horizontal: padding)
                : EdgeInsets.zero,
            child: Row(
              children: [
                ...state.fields.map(
                  (field) => CalculateCell(
                    key: Key(
                      '${field.id}-${state.calculationsByFieldId[field.id]?.id}',
                    ),
                    width: field.width!.toDouble(),
                    fieldInfo: field,
                    calculation: state.calculationsByFieldId[field.id],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
