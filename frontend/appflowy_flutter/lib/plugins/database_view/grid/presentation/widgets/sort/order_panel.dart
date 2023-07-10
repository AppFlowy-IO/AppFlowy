import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/sort/sort_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbenum.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class OrderPanel extends StatelessWidget {
  final Function(SortConditionPB) onCondition;
  const OrderPanel({required this.onCondition, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = SortConditionPB.values.map((condition) {
      return OrderPannelItem(
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

class OrderPannelItem extends StatelessWidget {
  final SortConditionPB condition;
  final Function(SortConditionPB) onCondition;
  const OrderPannelItem({
    required this.condition,
    required this.onCondition,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(condition.title),
        onTap: () => onCondition(condition),
      ),
    );
  }
}
