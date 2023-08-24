import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SelectableItemListMenu extends StatelessWidget {
  const SelectableItemListMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> items;
  final int selectedIndex;
  final void Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final item = items[index];
        return SelectableItem(
          isSelected: index == selectedIndex,
          item: item,
          onTap: () => onSelected(index),
        );
      },
      itemCount: items.length,
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
        text: FlowyText.medium(item),
        rightIcon: isSelected ? const FlowySvg(FlowySvgs.check_s) : null,
        onTap: onTap,
      ),
    );
  }
}
