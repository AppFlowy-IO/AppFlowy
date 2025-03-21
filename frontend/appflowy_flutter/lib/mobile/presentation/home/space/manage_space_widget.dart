import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/space/space_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;

import 'widgets.dart';

enum ManageSpaceType {
  create,
  edit,
}

class ManageSpaceWidget extends StatelessWidget {
  const ManageSpaceWidget({
    super.key,
    required this.controller,
    required this.permission,
    required this.selectedColor,
    required this.selectedIcon,
    required this.type,
  });

  final TextEditingController controller;
  final ValueNotifier<SpacePermission> permission;
  final ValueNotifier<String> selectedColor;
  final ValueNotifier<Icon?> selectedIcon;
  final ManageSpaceType type;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ManageSpaceNameOption(
          controller: controller,
          type: type,
        ),
        ManageSpacePermissionOption(permission: permission),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 560,
          ),
          child: ManageSpaceIconOption(
            selectedColor: selectedColor,
            selectedIcon: selectedIcon,
          ),
        ),
        const VSpace(60),
      ],
    );
  }
}
