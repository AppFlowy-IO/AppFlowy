import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/favourite_folder/mobile_home_favorite_folder.dart';
import 'package:appflowy/mobile/presentation/home/personal_folder/mobile_home_personal_folder.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileFolders extends StatelessWidget {
  const MobileFolders({
    super.key,
    required this.user,
    required this.workspaceSetting,
  });

  final UserProfilePB user;
  final WorkspaceSettingPB workspaceSetting;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<NotificationActionBloc>(),
        ),
        BlocProvider(
          create: (_) => MenuBloc(
            user: user,
            workspace: workspaceSetting.workspace,
          )..add(const MenuEvent.initial()),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        )
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) =>
                p.lastCreatedView?.id != c.lastCreatedView?.id,
            listener: (context, state) =>
                context.pushView(state.lastCreatedView!),
          ),
          BlocListener<NotificationActionBloc, NotificationActionState>(
            listener: (context, state) {
              final action = state.action;
              if (action != null) {
                switch (action.type) {
                  case ActionType.openView:
                    final view = context
                        .read<MenuBloc>()
                        .state
                        .views
                        .firstWhereOrNull((view) => action.objectId == view.id);

                    if (view != null) {
                      context.read<TabsBloc>().openPlugin(view);
                    }
                }
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            final menuState = context.watch<MenuBloc>().state;
            final favoriteState = context.watch<FavoriteBloc>().state;
            return Column(
              children: [
                if (favoriteState.views.isNotEmpty) ...[
                  MobileFavoriteFolder(
                    views: favoriteState.views,
                  ),
                  const VSpace(18.0),
                ],
                MobilePersonalFolder(
                  views: menuState.views,
                ),
                const VSpace(8.0),
              ],
            );
          },
        ),
      ),
    );
  }
}
