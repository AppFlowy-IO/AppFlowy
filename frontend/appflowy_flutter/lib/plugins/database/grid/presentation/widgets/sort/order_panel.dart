import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/sort_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbenum.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class OrderPanel extends StatelessWidget {
  const OrderPanel({required this.onCondition, super.key});

  final Function(SortConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = SortConditionPB.values.map((condition) {
      return OrderPanelItem(
        condition: condition,
        onCondition: onCondition,
      );
    }).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }
}

class OrderPanelItem extends StatelessWidget {
  const OrderPanelItem({
    super.key,
    required this.condition,
    required this.onCondition,
  });

  final SortConditionPB condition;
  final Function(SortConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText(condition.title),
        onTap: () => onCondition(condition),
      ),
    );
  }
}
