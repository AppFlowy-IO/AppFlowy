import 'package:appflowy/plugins/database/application/calculations/calculation_type_ext.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/type_option/number_format_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/calculations/calculations_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/calculations/field_type_calc_ext.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculation_selector.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculation_type_item.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/remove_calculation_button.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calculation_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
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
  final _cellScrollController = ScrollController();
  bool isSelected = false;
  bool isScrollable = false;

  @override
  void initState() {
    super.initState();
    _checkScrollable();
  }

  @override
  void didUpdateWidget(covariant CalculateCell oldWidget) {
    _checkScrollable();
    super.didUpdateWidget(oldWidget);
  }

  void _checkScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cellScrollController.hasClients) {
        setState(
          () =>
              isScrollable = _cellScrollController.position.maxScrollExtent > 0,
        );
      }
    });
  }

  @override
  void dispose() {
    _cellScrollController.dispose();
    super.dispose();
  }

  void setIsSelected(bool selected) => setState(() => isSelected = selected);

  @override
  Widget build(BuildContext context) {
    final prefix = _prefixFromFieldType(widget.fieldInfo.fieldType);

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
                ...widget.fieldInfo.fieldType.calculationsForFieldType().map(
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
        child: widget.calculation != null
            ? _showCalculateValue(context, prefix)
            : CalculationSelector(isSelected: isSelected),
      ),
    );
  }

  Widget _showCalculateValue(BuildContext context, String? prefix) {
    prefix = prefix != null ? '$prefix ' : '';
    final calculateValue =
        '$prefix${_withoutTrailingZeros(widget.calculation!.value)}';

    return FlowyTooltip(
      message: !isScrollable ? "" : null,
      richMessage: !isScrollable
          ? null
          : TextSpan(
              children: [
                TextSpan(
                  text: widget.calculation!.calculationType.shortLabel
                      .toUpperCase(),
                  style: context.tooltipTextStyle(),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: calculateValue,
                  style: context
                      .tooltipTextStyle()
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
      child: FlowyButton(
        radius: BorderRadius.zero,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _cellScrollController,
                key: ValueKey(widget.calculation!.id),
                reverse: true,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FlowyText(
                      widget.calculation!.calculationType.shortLabel
                          .toUpperCase(),
                      color: Theme.of(context).hintColor,
                      fontSize: 10,
                    ),
                    if (widget.calculation!.value.isNotEmpty) ...[
                      const HSpace(8),
                      FlowyText(
                        calculateValue,
                        color: AFThemeExtension.of(context).textColor,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _withoutTrailingZeros(String value) {
    if (trailingZerosRegex.hasMatch(value)) {
      final match = trailingZerosRegex.firstMatch(value)!;
      return match.group(1)!;
    }

    return value;
  }

  String? _prefixFromFieldType(FieldType fieldType) => switch (fieldType) {
        FieldType.Number =>
          NumberTypeOptionPB.fromBuffer(widget.fieldInfo.field.typeOptionData)
              .format
              .iconSymbol(false),
        _ => null,
      };
}
