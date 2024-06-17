import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/rename_view_dialog.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/create_space_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_header.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class SidebarSpace extends StatelessWidget {
  const SidebarSpace({
    super.key,
    this.isHoverEnabled = true,
    required this.userProfile,
  });

  final bool isHoverEnabled;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    // const sectionPadding = 16.0;
    return ValueListenableBuilder(
      valueListenable: getIt<MenuSharedState>().notifier,
      builder: (context, value, child) {
        return Provider.value(
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
              const _Space(),
              const VSpace(200),
            ],
          ),
        );
      },
    );
  }
}

class _Space extends StatefulWidget {
  const _Space();

  @override
  State<_Space> createState() => _SpaceState();
}

class _SpaceState extends State<_Space> {
  final ValueNotifier<bool> isHovered = ValueNotifier(false);
  final PropertyValueNotifier<bool> isExpandedNotifier =
      PropertyValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        if (state.spaces.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentSpace = state.currentSpace ?? state.spaces.first;

        return Column(
          children: [
            SidebarSpaceHeader(
              isExpanded: state.isExpanded,
              space: currentSpace,
              onAdded: () => _showCreatePagePopup(context, currentSpace),
              onCreateNewSpace: () => _showCreateSpaceDialog(context),
              onCollapseAllPages: () => isExpandedNotifier.value = true,
            ),
            MouseRegion(
              onEnter: (_) => isHovered.value = true,
              onExit: (_) => isHovered.value = false,
              child: _Pages(
                key: ValueKey(currentSpace.id),
                isExpandedNotifier: isExpandedNotifier,
                space: currentSpace,
                isHovered: isHovered,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateSpaceDialog(BuildContext context) {
    final spaceBloc = context.read<SpaceBloc>();
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: BlocProvider.value(
            value: spaceBloc,
            child: const CreateSpacePopup(),
          ),
        );
      },
    );
  }

  void _showCreatePagePopup(BuildContext context, ViewPB space) {
    createViewAndShowRenameDialogIfNeeded(
      context,
      LocaleKeys.newPageText.tr(),
      (viewName, _) {
        if (viewName.isNotEmpty) {
          context.read<SpaceBloc>().add(
                SpaceEvent.createPage(
                  name: viewName,
                  index: 0,
                  viewSection:
                      space.spacePermission == SpacePermission.publicToAll
                          ? ViewSectionPB.Public
                          : ViewSectionPB.Private,
                ),
              );

          context.read<SpaceBloc>().add(SpaceEvent.expand(space, true));
        }
      },
    );
  }
}

class _Pages extends StatelessWidget {
  const _Pages({
    super.key,
    required this.space,
    required this.isHovered,
    required this.isExpandedNotifier,
  });

  final ViewPB space;
  final ValueNotifier<bool> isHovered;
  final PropertyValueNotifier<bool> isExpandedNotifier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ViewBloc(view: space)..add(const ViewEvent.initial()),
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (context, state) {
          return Column(
            children: state.view.childViews
                .map(
                  (view) => ViewItem(
                    key: ValueKey('${space.id} ${view.id}'),
                    spaceType:
                        space.spacePermission == SpacePermission.publicToAll
                            ? FolderSpaceType.public
                            : FolderSpaceType.private,
                    isFirstChild: view.id == state.view.childViews.first.id,
                    view: view,
                    level: 0,
                    leftPadding: HomeSpaceViewSizes.leftPadding,
                    isFeedback: false,
                    isHovered: isHovered,
                    isExpandedNotifier: isExpandedNotifier,
                    onSelected: (viewContext, view) {
                      if (HardwareKeyboard.instance.isControlPressed) {
                        context.read<TabsBloc>().openTab(view);
                      }

                      context.read<TabsBloc>().openPlugin(view);
                    },
                    onTertiarySelected: (viewContext, view) =>
                        context.read<TabsBloc>().openTab(view),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
