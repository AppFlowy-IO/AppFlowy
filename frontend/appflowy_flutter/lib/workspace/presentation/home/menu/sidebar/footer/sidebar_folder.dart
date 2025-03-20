import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/space/folder_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/space/folder_views.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/create_space_popup.dart';
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
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        final spaces = state.spaces;
        final currentSpace = state.currentSpace ?? spaces.firstOrNull;
        if (spaces.isEmpty || currentSpace == null) {
          return const SizedBox.shrink();
        }
        return _FolderV2Loaded(
          currentSpace: currentSpace,
          isExpanded: state.isExpanded,
        );
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
    required this.currentSpace,
    required this.isExpanded,
  });

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

    switchToTheNextSpace.addListener(_switchToNextSpace);
  }

  @override
  void dispose() {
    switchToTheNextSpace.removeListener(_switchToNextSpace);
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
          onAdded: (layout) => _showCreatePagePopup(
            context,
            widget.currentSpace,
            layout,
          ),
          onCreateNewSpace: () => _showCreateSpaceDialog(context),
          onCollapseAllPages: () => isExpandedNotifier.value = true,
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
                  context.read<TabsBloc>().openTab(view.viewPB);
                }
                context.read<TabsBloc>().openPlugin(view.viewPB);
              },
              onTertiarySelected: (context, view) =>
                  context.read<TabsBloc>().openTab(view.viewPB),
            ),
          ),
        FlowyTextButton(
          'Refresh',
          onPressed: () {
            context
                .read<SpaceBloc>()
                .add(const SpaceEvent.didReceiveSpaceUpdate());
          },
        ),
      ],
    );
  }

  void _showCreatePagePopup(
    BuildContext context,
    FolderViewPB space,
    ViewLayoutPB layout,
  ) {
    context.read<SpaceBloc>().add(
          SpaceEvent.createPage(
            name: '',
            layout: layout,
            index: 0,
            openAfterCreate: true,
          ),
        );

    context.read<SpaceBloc>().add(SpaceEvent.expand(space, true));
  }

  void _showCreateSpaceDialog(BuildContext context) {
    final spaceBloc = context.read<SpaceBloc>();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: BlocProvider.value(
          value: spaceBloc,
          child: const CreateSpacePopup(),
        ),
      ),
    );
  }

  void _switchToNextSpace() {
    context.read<SpaceBloc>().add(const SpaceEvent.switchToNextSpace());
  }
}
