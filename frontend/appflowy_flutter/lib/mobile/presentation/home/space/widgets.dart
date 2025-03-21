import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/shared/icon_emoji_picker/colors.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;

import 'constants.dart';
import 'manage_space_widget.dart';
import 'space_permission_bottom_sheet.dart';

class ManageSpaceNameOption extends StatelessWidget {
  const ManageSpaceNameOption({
    super.key,
    required this.controller,
    required this.type,
  });

  final TextEditingController controller;
  final ManageSpaceType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: FlowyText(
            LocaleKeys.space_spaceName.tr(),
            fontSize: 14,
            figmaLineHeight: 20.0,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).hintColor,
          ),
        ),
        FlowyOptionTile.textField(
          controller: controller,
          autofocus: type == ManageSpaceType.create ? true : false,
          textFieldHintText: LocaleKeys.space_spaceNamePlaceholder.tr(),
        ),
        const VSpace(16),
      ],
    );
  }
}

class ManageSpacePermissionOption extends StatelessWidget {
  const ManageSpacePermissionOption({
    super.key,
    required this.permission,
  });

  final ValueNotifier<SpacePermission> permission;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: FlowyText(
            LocaleKeys.space_permission.tr(),
            fontSize: 14,
            figmaLineHeight: 20.0,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).hintColor,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: permission,
          builder: (context, value, child) => FlowyOptionTile.text(
            height: SpaceUIConstants.itemHeight,
            text: value.i18n,
            leftIcon: FlowySvg(value.icon),
            trailing: const FlowySvg(
              FlowySvgs.arrow_right_s,
            ),
            onTap: () {
              showMobileBottomSheet(
                context,
                showHeader: true,
                title: LocaleKeys.space_permission.tr(),
                showCloseButton: true,
                showDivider: false,
                showDragHandle: true,
                builder: (context) => SpacePermissionBottomSheet(
                  permission: value,
                  onAction: (value) {
                    permission.value = value;
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
        const VSpace(16),
      ],
    );
  }
}

class ManageSpaceIconOption extends StatefulWidget {
  const ManageSpaceIconOption({
    super.key,
    required this.selectedColor,
    required this.selectedIcon,
  });

  final ValueNotifier<String> selectedColor;
  final ValueNotifier<Icon?> selectedIcon;

  @override
  State<ManageSpaceIconOption> createState() => _ManageSpaceIconOptionState();
}

class _ManageSpaceIconOptionState extends State<ManageSpaceIconOption> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildColorOption(context),
        ..._buildSpaceIconOption(context),
      ],
    );
  }

  List<Widget> _buildColorOption(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: FlowyText(
          LocaleKeys.space_mSpaceIconColor.tr(),
          fontSize: 14,
          figmaLineHeight: 20.0,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).hintColor,
        ),
      ),
      ValueListenableBuilder(
        valueListenable: widget.selectedColor,
        builder: (context, selectedColor, child) {
          return FlowyOptionDecorateBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: builtInSpaceColors.map((color) {
                    return SpaceColorItem(
                      color: color,
                      selectedColor: selectedColor,
                      onSelected: (color) => widget.selectedColor.value = color,
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
      const VSpace(16),
    ];
  }

  List<Widget> _buildSpaceIconOption(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: FlowyText(
          LocaleKeys.space_mSpaceIcon.tr(),
          fontSize: 14,
          figmaLineHeight: 20.0,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).hintColor,
        ),
      ),
      Expanded(
        child: SizedBox(
          width: double.infinity,
          child: ValueListenableBuilder(
            valueListenable: widget.selectedColor,
            builder: (context, selectedColor, child) {
              return ValueListenableBuilder(
                valueListenable: widget.selectedIcon,
                builder: (context, selectedIcon, child) {
                  return FlowyOptionDecorateBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: _buildIconGroups(
                        context,
                        selectedColor,
                        selectedIcon,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      const VSpace(16),
    ];
  }

  Widget _buildIconGroups(
    BuildContext context,
    String selectedColor,
    Icon? selectedIcon,
  ) {
    final iconGroups = kIconGroups;
    if (iconGroups == null) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: iconGroups.length,
      itemBuilder: (context, index) {
        final iconGroup = iconGroups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VSpace(12.0),
            FlowyText(
              iconGroup.displayName.capitalize(),
              fontSize: 12,
              figmaLineHeight: 18.0,
              color: context.pickerTextColor,
            ),
            const VSpace(4.0),
            Center(
              child: Wrap(
                spacing: 10.0,
                runSpacing: 8.0,
                children: iconGroup.icons.map((icon) {
                  return SpaceIconItem(
                    icon: icon,
                    isSelected: selectedIcon?.name == icon.name,
                    selectedColor: selectedColor,
                    onSelectedIcon: (icon) => widget.selectedIcon.value = icon,
                  );
                }).toList(),
              ),
            ),
            const VSpace(12.0),
            if (index == iconGroups.length - 1) ...[
              const StreamlinePermit(),
            ],
          ],
        );
      },
    );
  }
}

class SpaceIconItem extends StatelessWidget {
  const SpaceIconItem({
    super.key,
    required this.icon,
    required this.onSelectedIcon,
    required this.isSelected,
    required this.selectedColor,
  });

  final Icon icon;
  final void Function(Icon icon) onSelectedIcon;
  final bool isSelected;
  final String selectedColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedGestureDetector(
      onTapUp: () => onSelectedIcon(icon),
      child: Container(
        width: 36,
        height: 36,
        decoration: isSelected
            ? BoxDecoration(
                color: Color(int.parse(selectedColor)),
                borderRadius: BorderRadius.circular(8.0),
              )
            : ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 0.5,
                    color: Color(0x661F2329),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        child: Center(
          child: FlowySvg.string(
            icon.content,
            size: const Size.square(18),
            color: isSelected
                ? Theme.of(context).colorScheme.surface
                : context.pickerIconColor,
            opacity: isSelected ? 1.0 : 0.7,
          ),
        ),
      ),
    );
  }
}

class SpaceColorItem extends StatelessWidget {
  const SpaceColorItem({
    super.key,
    required this.color,
    required this.selectedColor,
    required this.onSelected,
  });

  final String color;
  final String selectedColor;
  final void Function(String color) onSelected;

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Color(int.parse(color)),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    final decoration = color != selectedColor
        ? null
        : ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1.50,
                color: Theme.of(context).colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(21),
            ),
          );

    return AnimatedGestureDetector(
      onTapUp: () => onSelected(color),
      child: Container(
        width: 36,
        height: 36,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

extension on SpacePermission {
  String get i18n {
    switch (this) {
      case SpacePermission.public:
        return LocaleKeys.space_publicPermission.tr();
      case SpacePermission.private:
        return LocaleKeys.space_privatePermission.tr();
    }
  }

  FlowySvgData get icon {
    switch (this) {
      case SpacePermission.public:
        return FlowySvgs.space_permission_public_s;
      case SpacePermission.private:
        return FlowySvgs.space_permission_private_s;
    }
  }
}
