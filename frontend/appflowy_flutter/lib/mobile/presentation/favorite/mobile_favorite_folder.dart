import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/favorite_folder/mobile_home_favorite_folder.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_state_container.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MobileFavoritePageFolder extends StatelessWidget {
  const MobileFavoritePageFolder({
    super.key,
    required this.userProfile,
    required this.workspaceSetting,
  });

  final UserProfilePB userProfile;
  final WorkspaceSettingPB workspaceSetting;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MenuBloc(
            user: userProfile,
            workspaceId: workspaceSetting.workspaceId,
          )..add(const MenuEvent.initial()),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) =>
                p.lastCreatedView?.id != c.lastCreatedView?.id,
            listener: (context, state) =>
                context.pushView(state.lastCreatedView!),
          ),
        ],
        child: Builder(
          builder: (context) {
            final favoriteState = context.watch<FavoriteBloc>().state;
            if (favoriteState.views.isEmpty) {
              return FlowyMobileStateContainer.info(
                emoji: '😁',
                title: LocaleKeys.favorite_noFavorite.tr(),
                description: LocaleKeys.favorite_noFavoriteHintText.tr(),
              );
            }
            return Scrollbar(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SlidableAutoCloseBehavior(
                    child: Column(
                      children: [
                        MobileFavoriteFolder(
                          showHeader: false,
                          forceExpanded: true,
                          views: favoriteState.views,
                        ),
                        const VSpace(100.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
