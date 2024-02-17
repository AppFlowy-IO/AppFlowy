import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/calculations/calculation_type_ext.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/grid/application/calculations/calculations_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculation_selector.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculation_type_item.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/remove_calculation_button.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calculation_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalculateCell extends StatefulWidget {
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
  State<CalculateCell> createState() => _CalculateCellState();
}

class _CalculateCellState extends State<CalculateCell> {
  bool isSelected = false;

  void setIsSelected(bool selected) => setState(() => isSelected = selected);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      width: widget.width,
      child: AppFlowyPopover(
        constraints: BoxConstraints.loose(const Size(150, 200)),
        direction: PopoverDirection.bottomWithCenterAligned,
        onClose: () => setIsSelected(false),
        popupBuilder: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setIsSelected(true);
            }
          });

          return SingleChildScrollView(
            child: Column(
              children: [
                if (widget.calculation != null)
                  RemoveCalculationButton(
                    onTap: () => context.read<CalculationsBloc>().add(
                          CalculationsEvent.removeCalculation(
                            widget.fieldInfo.id,
                            widget.calculation!.id,
                          ),
                        ),
                  ),
                ...CalculationType.values.map(
                  (type) => CalculationTypeItem(
                    type: type,
                    onTap: () {
                      if (type != widget.calculation?.calculationType) {
                        context.read<CalculationsBloc>().add(
                              CalculationsEvent.updateCalculationType(
                                widget.fieldInfo.id,
                                type,
                                calculationId: widget.calculation?.id,
                              ),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
        child: widget.fieldInfo.fieldType == FieldType.Number
            ? widget.calculation != null
                ? _showCalculateValue(context)
                : CalculationSelector(isSelected: isSelected)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _showCalculateValue(BuildContext context) {
    return FlowyButton(
      radius: BorderRadius.zero,
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      text: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: FlowyText(
              widget.calculation!.calculationType.label,
              color: Theme.of(context).hintColor,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.calculation!.value.isNotEmpty) ...[
            const HSpace(8),
            Flexible(
              child: FlowyText(
                _withoutTrailingZeros(widget.calculation!.value),
                color: AFThemeExtension.of(context).textColor,
              ),
            ),
          ],
          const HSpace(8),
          FlowySvg(
            FlowySvgs.arrow_down_s,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }

  String _withoutTrailingZeros(String value) {
    final regex = RegExp(r'^(\d+(?:\.\d*?[1-9](?=0|\b))?)\.?0*$');
    if (regex.hasMatch(value)) {
      final match = regex.firstMatch(value)!;
      return match.group(1)!;
    }

    return value;
  }
}
