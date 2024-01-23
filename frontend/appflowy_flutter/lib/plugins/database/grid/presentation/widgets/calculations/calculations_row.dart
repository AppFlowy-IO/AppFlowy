import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/calculations/calculation_type_ext.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/grid/application/calculations/calculations_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calculation_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridCalculationsRow extends StatelessWidget {
  final String viewId;

  const GridCalculationsRow({
    super.key,
    required this.viewId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CalculationsBloc(
        viewId: context.read<GridBloc>().databaseController.viewId,
        fieldController:
            context.read<GridBloc>().databaseController.fieldController,
      )..add(const CalculationsEvent.started()),
      child: BlocBuilder<CalculationsBloc, CalculationsState>(
        builder: (context, state) {
          return Padding(
            padding: GridSize.contentInsets,
            child: Row(
              children: [
                ...state.fields.map(
                  (field) => CalculateCell(
                    key: Key(
                      '${field.id}-${state.calculationsByFieldId[field.id]?.id}',
                    ),
                    width: field.fieldSettings!.width.toDouble(),
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

class CalculateCell extends StatelessWidget {
  const CalculateCell({
    super.key,
    required this.fieldInfo,
    required this.width,
    this.calculation,
  });

  final FieldInfo fieldInfo;
  final double width;
  final CalculationPB? calculation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      width: width,
      child: AppFlowyPopover(
        constraints: BoxConstraints.loose(const Size(150, 200)),
        direction: PopoverDirection.bottomWithCenterAligned,
        popupBuilder: (_) => SingleChildScrollView(
          child: Column(
            children: [
              if (calculation != null)
                RemoveCalculationButton(
                  onTap: () {
                    context.read<CalculationsBloc>().add(
                          CalculationsEvent.removeCalculation(
                            fieldInfo.id,
                            calculation!.id,
                          ),
                        );
                  },
                ),
              ...CalculationType.values.map(
                (type) => CalculationTypeItem(
                  type: type,
                  onTap: () {
                    if (type != calculation?.calculationType) {
                      context.read<CalculationsBloc>().add(
                            CalculationsEvent.updateCalculationType(
                              fieldInfo.id,
                              type,
                              calculationId: calculation?.id,
                            ),
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        child: fieldInfo.fieldType == FieldType.Number
            ? calculation != null
                ? _showCalculateValue(context)
                : _showCalculateText(context)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _showCalculateText(BuildContext context) {
    return FlowyButton(
      radius: BorderRadius.zero,
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      text: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: FlowyText(
              'Calculate',
              color: Theme.of(context).hintColor,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(8),
          FlowySvg(
            FlowySvgs.arrow_down_s,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }

  Widget _showCalculateValue(BuildContext context) {
    return FlowyButton(
      radius: BorderRadius.zero,
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      text: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: FlowyText(
              calculation!.calculationType.label,
              color: Theme.of(context).hintColor,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(8),
          calculation!.value.isEmpty
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Flexible(child: FlowyText(calculation!.value)),
          const HSpace(8),
          FlowySvg(
            FlowySvgs.arrow_down_s,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }
}

class CalculationTypeItem extends StatelessWidget {
  const CalculationTypeItem({
    super.key,
    required this.type,
    required this.onTap,
  });

  final CalculationType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(type.label, overflow: TextOverflow.ellipsis),
        onTap: () {
          onTap();
          PopoverContainer.of(context).close();
        },
      ),
    );
  }
}

class RemoveCalculationButton extends StatelessWidget {
  const RemoveCalculationButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: const FlowyText.medium(
          'None',
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          onTap();
          PopoverContainer.of(context).close();
        },
      ),
    );
  }
}
