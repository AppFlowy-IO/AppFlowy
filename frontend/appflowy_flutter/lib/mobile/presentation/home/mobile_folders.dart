import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/section_folder/mobile_home_section_folder.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// Contains Public And Private Sections
class MobileFolders extends StatelessWidget {
  const MobileFolders({
    super.key,
    required this.user,
    required this.workspaceSetting,
    required this.showFavorite,
  });

  final UserProfilePB user;
  final WorkspaceSettingPB workspaceSetting;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SidebarSectionsBloc()
            ..add(
              SidebarSectionsEvent.initial(
                user,
                workspaceSetting.workspaceId,
              ),
            ),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        ),
      ],
      child: BlocConsumer<SidebarSectionsBloc, SidebarSectionsState>(
        listenWhen: (p, c) =>
            p.lastCreatedRootView?.id != c.lastCreatedRootView?.id,
        listener: (context, state) {
          final lastCreatedRootView = state.lastCreatedRootView;
          if (lastCreatedRootView != null) {
            context.pushView(lastCreatedRootView);
          }
        },
        builder: (context, state) {
          return SlidableAutoCloseBehavior(
            child: Column(
              children: [
                // TODO: disable the public folder in local mode.
                MobileSectionFolder(
                  title: 'Public',
                  views: state.section.publicViews,
                ),
                const VSpace(8.0),
                MobileSectionFolder(
                  title: 'Private',
                  views: state.section.privateViews,
                ),
                const VSpace(8.0),
              ],
            ),
          );
        },
      ),
    );
  }
}
