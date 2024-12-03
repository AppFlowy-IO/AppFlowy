import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;

final builtInSpaceColors = [
  '0xFFA34AFD',
  '0xFFFB006D',
  '0xFF00C8FF',
  '0xFFFFBA00',
  '0xFFF254BC',
  '0xFF2AC985',
  '0xFFAAD93D',
  '0xFF535CE4',
  '0xFF808080',
  '0xFFD2515F',
  '0xFF409BF8',
  '0xFFFF8933',
];

String generateRandomSpaceColor() {
  final random = Random();
  return builtInSpaceColors[random.nextInt(builtInSpaceColors.length)];
}

final builtInSpaceIcons =
    List.generate(15, (index) => 'space_icon_${index + 1}');

class SpaceIconPopup extends StatefulWidget {
  const SpaceIconPopup({
    super.key,
    this.icon,
    this.iconColor,
    this.cornerRadius = 16,
    this.space,
    required this.onIconChanged,
  });

  final String? icon;
  final String? iconColor;
  final ViewPB? space;
  final void Function(String? icon, String? color) onIconChanged;
  final double cornerRadius;

  @override
  State<SpaceIconPopup> createState() => _SpaceIconPopupState();
}

class _SpaceIconPopupState extends State<SpaceIconPopup> {
  late ValueNotifier<String?> selectedIcon = ValueNotifier<String?>(
    widget.icon,
  );
  late ValueNotifier<String> selectedColor = ValueNotifier<String>(
    widget.iconColor ?? builtInSpaceColors.first,
  );

  @override
  void dispose() {
    selectedColor.dispose();
    selectedIcon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      offset: const Offset(0, 4),
      constraints: BoxConstraints.loose(const Size(360, 432)),
      margin: const EdgeInsets.all(0),
      direction: PopoverDirection.bottomWithCenterAligned,
      child: _buildPreview(),
      popupBuilder: (context) {
        return FlowyIconEmojiPicker(
          tabs: const [PickerTabType.icon],
          onSelectedIcon: (group, icon, color) {
            if (group == null || icon == null) {
              selectedIcon.value = null;
            } else {
              selectedIcon.value = '${group.name}/${icon.name}';
            }

            if (color != null) {
              selectedColor.value = color;
            }

            widget.onIconChanged(selectedIcon.value, selectedColor.value);

            PopoverContainer.of(context).close();
          },
        );
      },
    );
  }

  Widget _buildPreview() {
    bool onHover = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) => setState(() => onHover = true),
          onExit: (event) => setState(() => onHover = false),
          child: ValueListenableBuilder(
            valueListenable: selectedColor,
            builder: (_, color, __) {
              return ValueListenableBuilder(
                valueListenable: selectedIcon,
                builder: (_, value, __) {
                  Widget child;
                  if (value == null) {
                    if (widget.space == null) {
                      child = DefaultSpaceIcon(
                        cornerRadius: widget.cornerRadius,
                        dimension: 32,
                        iconDimension: 32,
                      );
                    } else {
                      child = SpaceIcon(
                        dimension: 32,
                        space: widget.space!,
                        svgSize: 24,
                        cornerRadius: widget.cornerRadius,
                      );
                    }
                  } else if (value.contains('space_icon')) {
                    child = ClipRRect(
                      borderRadius: BorderRadius.circular(widget.cornerRadius),
                      child: Container(
                        color: Color(int.parse(color)),
                        child: Align(
                          child: FlowySvg(
                            FlowySvgData('assets/flowy_icons/16x/$value.svg'),
                            size: const Size.square(42),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                    );
                  } else {
                    final content = kIconGroups?.findSvgContent(value);
                    if (content == null) {
                      child = const SizedBox.shrink();
                    } else {
                      child = ClipRRect(
                        borderRadius:
                            BorderRadius.circular(widget.cornerRadius),
                        child: Container(
                          color: Color(int.parse(color)),
                          child: Align(
                            child: FlowySvg.string(
                              content,
                              size: const Size.square(24),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  if (onHover) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(opacity: 0.2, child: child),
                        ),
                        const Center(
                          child: FlowySvg(
                            FlowySvgs.view_item_rename_s,
                            size: Size.square(20),
                          ),
                        ),
                      ],
                    );
                  }
                  return child;
                },
              );
            },
          ),
        );
      },
    );
  }
}

class SpaceIconPicker extends StatefulWidget {
  const SpaceIconPicker({
    super.key,
    required this.onIconChanged,
    this.skipFirstNotification = false,
    this.icon,
    this.iconColor,
  });

  final bool skipFirstNotification;
  final void Function(String icon, String color) onIconChanged;
  final String? icon;
  final String? iconColor;

  @override
  State<SpaceIconPicker> createState() => _SpaceIconPickerState();
}

class _SpaceIconPickerState extends State<SpaceIconPicker> {
  late ValueNotifier<String> selectedColor =
      ValueNotifier<String>(widget.iconColor ?? builtInSpaceColors.first);
  late ValueNotifier<String> selectedIcon =
      ValueNotifier<String>(widget.icon ?? builtInSpaceIcons.first);

  @override
  void initState() {
    super.initState();

    if (!widget.skipFirstNotification) {
      widget.onIconChanged(selectedIcon.value, selectedColor.value);
    }

    selectedColor.addListener(_onColorChanged);
    selectedIcon.addListener(_onIconChanged);
  }

  void _onColorChanged() {
    widget.onIconChanged(selectedIcon.value, selectedColor.value);
  }

  void _onIconChanged() {
    widget.onIconChanged(selectedIcon.value, selectedColor.value);
  }

  @override
  void dispose() {
    selectedColor.removeListener(_onColorChanged);
    selectedColor.dispose();

    selectedIcon.removeListener(_onIconChanged);
    selectedIcon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyText.regular(
          LocaleKeys.space_spaceIconBackground.tr(),
          color: Theme.of(context).hintColor,
        ),
        const VSpace(10.0),
        _Colors(
          selectedColor: selectedColor.value,
          onColorSelected: (color) => selectedColor.value = color,
        ),
        const VSpace(12.0),
        FlowyText.regular(
          LocaleKeys.space_spaceIcon.tr(),
          color: Theme.of(context).hintColor,
        ),
        const VSpace(10.0),
        ValueListenableBuilder(
          valueListenable: selectedColor,
          builder: (_, value, ___) => _Icons(
            selectedColor: value,
            selectedIcon: selectedIcon.value,
            onIconSelected: (icon) => selectedIcon.value = icon,
          ),
        ),
      ],
    );
  }
}

class _Colors extends StatefulWidget {
  const _Colors({
    required this.selectedColor,
    required this.onColorSelected,
  });

  final String selectedColor;
  final void Function(String color) onColorSelected;

  @override
  State<_Colors> createState() => _ColorsState();
}

class _ColorsState extends State<_Colors> {
  late String selectedColor = widget.selectedColor;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 6,
      mainAxisSpacing: 4.0,
      children: builtInSpaceColors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() => selectedColor = color);

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
                color: Color(int.parse(color)),
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

  final String selectedColor;
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
      children: builtInSpaceIcons.map((icon) {
        return GestureDetector(
          onTap: () {
            setState(() => selectedIcon = icon);

            widget.onIconSelected(icon);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: FlowySvg(
              FlowySvgData('assets/flowy_icons/16x/$icon.svg'),
              color: Color(int.parse(widget.selectedColor)),
              blendMode: BlendMode.srcOut,
            ),
          ),
        );
      }).toList(),
    );
  }
}
