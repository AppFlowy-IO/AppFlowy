import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/personal_folder/mobile_home_personal_folder.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_root_views_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
          create: (_) => SidebarRootViewsBloc()
            ..add(
              SidebarRootViewsEvent.initial(
                user,
                workspaceSetting.workspaceId,
              ),
            ),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<SidebarRootViewsBloc, SidebarRootViewState>(
            listenWhen: (p, c) =>
                p.lastCreatedRootView?.id != c.lastCreatedRootView?.id,
            listener: (context, state) =>
                context.pushView(state.lastCreatedRootView!),
          ),
        ],
        child: Builder(
          builder: (context) {
            final menuState = context.watch<SidebarRootViewsBloc>().state;
            return SlidableAutoCloseBehavior(
              child: Column(
                children: [
                  MobilePersonalFolder(
                    views: menuState.views,
                  ),
                  const VSpace(8.0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
