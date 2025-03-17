import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/view/folder_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/view/folder_views.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            // favorite
            BlocBuilder<FavoriteBloc, FavoriteState>(
              builder: (context, state) {
                if (state.views.isEmpty) {
                  return const SizedBox.shrink();
                }
                return FavoriteFolder(
                  views: state.views.map((e) => e.item).toList(),
                );
              },
            ),
            const VSpace(16.0),
            // spaces
            const _FolderV2(),
            const VSpace(200),
          ],
        ),
      ),
    );
  }
}

class _FolderV2 extends StatelessWidget {
  const _FolderV2();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FolderV2Bloc, FolderV2State>(
      builder: (context, state) {
        switch (state) {
          case FolderV2Initial():
            return const SizedBox.shrink();
          case FolderV2Loading():
            return const _FolderV2Loading();
          case FolderV2Loaded():
            return _FolderV2Loaded(
              folderView: state.folderView,
              currentSpace: state.currentSpace,
              isExpanded: state.isExpanded,
            );
          case FolderV2Error():
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _FolderV2Loading extends StatelessWidget {
  const _FolderV2Loading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _FolderV2Loaded extends StatefulWidget {
  const _FolderV2Loaded({
    required this.folderView,
    required this.currentSpace,
    required this.isExpanded,
  });

  final FolderViewPB folderView;
  final bool isExpanded;
  final FolderViewPB currentSpace;

  @override
  State<_FolderV2Loaded> createState() => _FolderV2LoadedState();
}

class _FolderV2LoadedState extends State<_FolderV2Loaded> {
  final isHovered = ValueNotifier(false);
  final isExpandedNotifier = PropertyValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    isHovered.dispose();
    isExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FolderSpaceMenu(
          isExpanded: widget.isExpanded,
          space: widget.currentSpace,
          onAdded: (layout) {},
          onCreateNewSpace: () {},
          onCollapseAllPages: () {},
        ),
        if (widget.isExpanded)
          MouseRegion(
            onEnter: (_) => isHovered.value = true,
            onExit: (_) => isHovered.value = false,
            child: FolderViews(
              isExpandedNotifier: isExpandedNotifier,
              space: widget.currentSpace,
              isHovered: isHovered,
              onSelected: (context, view) {
                if (HardwareKeyboard.instance.isControlPressed) {
                  context.read<TabsBloc>().openTab(view);
                }
                context.read<TabsBloc>().openPlugin(view);
              },
              onTertiarySelected: (context, view) =>
                  context.read<TabsBloc>().openTab(view),
            ),
          ),
        FlowyTextButton(
          'Refresh',
          onPressed: () {
            context.read<FolderV2Bloc>().add(FolderV2ReloadFolderViews());
          },
        ),
      ],
    );
  }
}
