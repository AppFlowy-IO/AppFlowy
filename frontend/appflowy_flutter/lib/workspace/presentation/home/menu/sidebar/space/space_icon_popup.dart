import 'dart:convert';
import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
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
          onSelectedEmoji: (r) {
            if (r.type == FlowyIconType.icon) {
              try {
                final iconsData = IconsData.fromJson(jsonDecode(r.emoji));
                final color = iconsData.color;
                selectedIcon.value =
                    '${iconsData.groupName}/${iconsData.iconName}';
                if (color != null) {
                  selectedColor.value = color;
                }
                widget.onIconChanged(selectedIcon.value, selectedColor.value);
              } on FormatException catch (e) {
                selectedIcon.value = '';
                widget.onIconChanged(selectedIcon.value, selectedColor.value);
                Log.warn('SpaceIconPopup onSelectedEmoji error:$e');
              }
            }
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
