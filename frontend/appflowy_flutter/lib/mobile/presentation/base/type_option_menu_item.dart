import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class TypeOptionMenuItemValue<T> {
  const TypeOptionMenuItemValue({
    required this.value,
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.onTap,
  });

  final T value;
  final FlowySvgData icon;
  final String text;
  final Color backgroundColor;
  final void Function(BuildContext context, T value) onTap;
}

class TypeOptionMenu<T> extends StatelessWidget {
  const TypeOptionMenu({
    super.key,
    required this.values,
    this.width = 94,
    this.iconWidth = 72,
    this.scaleFactor = 1.0,
    this.maxAxisSpacing = 18,
    this.crossAxisCount = 3,
  });

  final List<TypeOptionMenuItemValue<T>> values;

  final double iconWidth;
  final double width;
  final double scaleFactor;
  final double maxAxisSpacing;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return _GridView(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: maxAxisSpacing * scaleFactor,
      itemWidth: width * scaleFactor,
      children: values
          .map(
            (value) => _TypeOptionMenuItem<T>(
              value: value,
              width: width,
              iconWidth: iconWidth,
              scaleFactor: scaleFactor,
            ),
          )
          .toList(),
    );
  }
}

class _TypeOptionMenuItem<T> extends StatelessWidget {
  const _TypeOptionMenuItem({
    required this.value,
    this.width = 94,
    this.iconWidth = 72,
    this.scaleFactor = 1.0,
  });

  final TypeOptionMenuItemValue<T> value;
  final double iconWidth;
  final double width;
  final double scaleFactor;

  double get scaledIconWidth => iconWidth * scaleFactor;
  double get scaledWidth => width * scaleFactor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => value.onTap(context, value.value),
      child: Column(
        children: [
          Container(
            height: scaledIconWidth,
            width: scaledIconWidth,
            decoration: ShapeDecoration(
              color: value.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24 * scaleFactor),
              ),
            ),
            padding: EdgeInsets.all(21 * scaleFactor),
            child: FlowySvg(
              value.icon,
            ),
          ),
          const VSpace(6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: scaledWidth,
            ),
            child: FlowyText(
              value.text,
              fontSize: 14.0,
              maxLines: 2,
              lineHeight: 1.0,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  const _GridView({
    required this.children,
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.itemWidth,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i += crossAxisCount)
          Padding(
            padding: EdgeInsets.only(bottom: mainAxisSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var j = 0; j < crossAxisCount; j++)
                  i + j < children.length
                      ? SizedBox(
                          width: itemWidth,
                          child: children[i + j],
                        )
                      : HSpace(itemWidth),
              ],
            ),
          ),
      ],
    );
  }
}
