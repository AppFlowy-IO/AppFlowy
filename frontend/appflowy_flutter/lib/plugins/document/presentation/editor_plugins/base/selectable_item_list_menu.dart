import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SelectableItemListMenu extends StatelessWidget {
  const SelectableItemListMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.shrinkWrap = false,
  });

  final List<String> items;
  final int selectedIndex;
  final void Function(int) onSelected;

  /// shrinkWrapping is useful in cases where you have a list of
  /// limited amount of items. It will make the list take the minimum
  /// amount of space required to show all the items.
  ///
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) => SelectableItem(
        isSelected: index == selectedIndex,
        item: items[index],
        onTap: () => onSelected(index),
      ),
    );
  }
}

class SelectableItem extends StatelessWidget {
  const SelectableItem({
    super.key,
    required this.isSelected,
    required this.item,
    required this.onTap,
  });

  final bool isSelected;
  final String item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(
          item,
          lineHeight: 1.0,
        ),
        rightIcon: isSelected ? const FlowySvg(FlowySvgs.check_s) : null,
        onTap: onTap,
      ),
    );
  }
}
