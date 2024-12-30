import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

class IconColorPicker extends StatelessWidget {
  const IconColorPicker({
    super.key,
    required this.onSelected,
  });

  final void Function(String color) onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 6,
      mainAxisSpacing: 4.0,
      children: builtInSpaceColors.map((color) {
        return FlowyHover(
          style: HoverStyle(borderRadius: BorderRadius.circular(8.0)),
          child: GestureDetector(
            onTap: () => onSelected(color),
            child: Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(5.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: Color(int.parse(color)),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0x2D333333)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
