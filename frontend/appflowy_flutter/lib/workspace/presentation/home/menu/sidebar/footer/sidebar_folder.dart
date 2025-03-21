import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/presentation/favorite/folder_favorite_section.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/presentation/space/folder_space_section.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SidebarFolderV2 extends StatelessWidget {
  const SidebarFolderV2({
    super.key,
    required this.userProfile,
    this.isHoverEnabled = true,
  });

  final UserProfilePB userProfile;
  final bool isHoverEnabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: getIt<MenuSharedState>().notifier,
      builder: (_, __, ___) => Provider.value(
        value: userProfile,
        child: Column(
          children: [
            const VSpace(4.0),
            // favorite section
            const FavoriteSection(),
            const VSpace(16.0),
            // space section
            FolderSpaceSection(),
            const VSpace(200),
          ],
        ),
      ),
    );
  }
}
