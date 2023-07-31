import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FlowyColorOption {
  const FlowyColorOption({
    required this.color,
    required this.name,
  });

  final Color color;
  final String name;
}

class FlowyColorPicker extends StatelessWidget {
  final List<FlowyColorOption> colors;
  final Color? selected;
  final Function(Color color, int index)? onTap;
  final double separatorSize;
  final double iconSize;
  final double itemHeight;
  final Border? border;

  const FlowyColorPicker({
    Key? key,
    required this.colors,
    this.selected,
    this.onTap,
    this.separatorSize = 4,
    this.iconSize = 16,
    this.itemHeight = 32,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      controller: ScrollController(),
      separatorBuilder: (context, index) {
        return VSpace(separatorSize);
      },
      itemCount: colors.length,
      physics: StyledScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return _buildColorOption(colors[index], index);
      },
    );
  }

  Widget _buildColorOption(
    FlowyColorOption option,
    int i,
  ) {
    Widget? checkmark;
    if (selected == option.color) {
      checkmark = svgWidget("grid/checkmark");
    }

    final colorIcon = SizedBox.square(
      dimension: iconSize,
      child: Container(
        decoration: BoxDecoration(
          color: option.color,
          shape: BoxShape.circle,
          // border: border,
        ),
      ),
    );

    return SizedBox(
      height: itemHeight,
      child: FlowyButton(
        text: FlowyText.medium(option.name),
        leftIcon: colorIcon,
        rightIcon: checkmark,
        onTap: () {
          onTap?.call(option.color, i);
        },
      ),
    );
  }
}
