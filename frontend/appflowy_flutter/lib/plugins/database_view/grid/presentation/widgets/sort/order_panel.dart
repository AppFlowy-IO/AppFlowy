import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class OrderPanel extends StatelessWidget {
  final Function(SortConditionPB) onCondition;
  const OrderPanel({required this.onCondition, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = SortConditionPB.values.map((condition) {
      return SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          text: FlowyText.medium(textFromCondition(condition)),
          onTap: () => onCondition(condition),
        ),
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

  String textFromCondition(SortConditionPB condition) {
    switch (condition) {
      case SortConditionPB.Ascending:
        return LocaleKeys.grid_sort_ascending.tr();
      case SortConditionPB.Descending:
        return LocaleKeys.grid_sort_descending.tr();
    }
    return "";
  }
}
