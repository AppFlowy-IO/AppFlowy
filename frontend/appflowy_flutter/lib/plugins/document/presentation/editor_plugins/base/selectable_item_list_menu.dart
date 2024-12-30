import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SelectableItemListMenu extends StatelessWidget {
  const SelectableItemListMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.shrinkWrap = false,
    this.controller,
  });

  final List<String> items;
  final int selectedIndex;
  final void Function(int) onSelected;
  final ItemScrollController? controller;

  /// shrinkWrapping is useful in cases where you have a list of
  /// limited amount of items. It will make the list take the minimum
  /// amount of space required to show all the items.
  ///
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemScrollController: controller,
      initialScrollIndex: max(0, selectedIndex),
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
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }
}
