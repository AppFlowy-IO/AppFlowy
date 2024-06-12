import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';

final _builtInColors = [
  0xFFA34AFD,
  0xFFFB006D,
  0xFF00C8FF,
  0xFFFFBA00,
  0xFFF254BC,
  0xFF2AC985,
  0xFFAAD93D,
  0xFF535CE4,
  0xFF808080,
  0xFFD2515F,
  0xFF409BF8,
  0xFFFF8933,
];

final _buildInIcons = List.generate(15, (index) => 'space_icon_${index + 1}');

class SpaceIconPopup extends StatefulWidget {
  const SpaceIconPopup({super.key});

  @override
  State<SpaceIconPopup> createState() => _SpaceIconPopupState();
}

class _SpaceIconPopupState extends State<SpaceIconPopup> {
  ValueNotifier<int> selectedColor = ValueNotifier<int>(_builtInColors.first);
  String selectedIcon = _buildInIcons.first;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      offset: const Offset(0, 4),
      decoration: FlowyDecoration.decoration(
        Theme.of(context).cardColor,
        Theme.of(context).colorScheme.shadow,
        borderRadius: 10,
      ),
      constraints: const BoxConstraints(maxWidth: 220),
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      direction: PopoverDirection.bottomWithCenterAligned,
      child: const FlowySvg(
        FlowySvgs.space_icon_s,
        blendMode: null,
      ),
      popupBuilder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText.regular(
            'Background color',
            color: Theme.of(context).hintColor,
          ),
          const VSpace(8.0),
          _Colors(
            selectedColor: selectedColor.value,
            onColorSelected: (color) {
              selectedColor.value = color;
            },
          ),
          const VSpace(12.0),
          FlowyText.regular(
            'Icon',
            color: Theme.of(context).hintColor,
          ),
          const VSpace(8.0),
          ValueListenableBuilder(
            valueListenable: selectedColor,
            builder: (_, value, ___) => _Icons(
              selectedColor: value,
              selectedIcon: selectedIcon,
              onIconSelected: (icon) {
                selectedIcon = icon;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Colors extends StatefulWidget {
  const _Colors({
    required this.selectedColor,
    required this.onColorSelected,
  });

  final int selectedColor;
  final void Function(int color) onColorSelected;

  @override
  State<_Colors> createState() => _ColorsState();
}

class _ColorsState extends State<_Colors> {
  late int selectedColor = widget.selectedColor;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 6,
      mainAxisSpacing: 4.0,
      children: _builtInColors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = color;
            });

            widget.onColorSelected(color);
          },
          child: Container(
            margin: const EdgeInsets.all(2.0),
            padding: const EdgeInsets.all(2.0),
            decoration: selectedColor == color
                ? ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1.50,
                        strokeAlign: BorderSide.strokeAlignOutside,
                        color: Color(0xFF00BCF0),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  )
                : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(color),
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Icons extends StatefulWidget {
  const _Icons({
    required this.selectedColor,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  final int selectedColor;
  final String selectedIcon;
  final void Function(String color) onIconSelected;

  @override
  State<_Icons> createState() => _IconsState();
}

class _IconsState extends State<_Icons> {
  late String selectedIcon = widget.selectedIcon;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 5,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 12.0,
      children: _buildInIcons.map((icon) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedIcon = icon;
            });

            widget.onIconSelected(icon);
          },
          child: FlowySvg(
            FlowySvgData('assets/flowy_icons/16x/$icon.svg'),
            color: Color(widget.selectedColor),
            blendMode: BlendMode.srcOut,
          ),
        );
      }).toList(),
    );
  }
}
