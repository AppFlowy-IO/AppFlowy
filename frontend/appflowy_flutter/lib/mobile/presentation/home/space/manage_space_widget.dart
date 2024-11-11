import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart' hide Icon;

import '_widgets.dart';

class ManageSpaceWidget extends StatefulWidget {
  const ManageSpaceWidget({
    super.key,
  });

  @override
  State<ManageSpaceWidget> createState() => _ManageSpaceWidgetState();
}

class _ManageSpaceWidgetState extends State<ManageSpaceWidget> {
  final controller = TextEditingController();
  final permission = ValueNotifier<SpacePermission>(
    SpacePermission.publicToAll,
  );
  final selectedColor = ValueNotifier<String>(
    builtInSpaceColors.first,
  );
  final selectedIcon = ValueNotifier<Icon?>(
    kIconGroups?.first.icons.first,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    permission.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ManageSpaceNameOption(controller: controller),
        ManageSpacePermissionOption(permission: permission),
        ManageSpaceIconOption(
          selectedColor: selectedColor,
          selectedIcon: selectedIcon,
        ),
        const VSpace(200),
      ],
    );
  }
}
