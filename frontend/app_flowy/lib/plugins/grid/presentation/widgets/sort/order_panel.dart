import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/sort_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class OrderPanel extends StatelessWidget {
  final Function(GridSortConditionPB) onCondition;
  const OrderPanel({required this.onCondition, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = GridSortConditionPB.values.map((condition) {
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

  String textFromCondition(GridSortConditionPB condition) {
    switch (condition) {
      case GridSortConditionPB.Ascending:
        return LocaleKeys.grid_sort_ascending.tr();
      case GridSortConditionPB.Descending:
        return LocaleKeys.grid_sort_descending.tr();
    }
    return "";
  }
}
