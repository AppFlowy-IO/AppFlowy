import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/card/mobile_view_card.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_state_container.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileFavoriteSpace extends StatelessWidget {
  const MobileFavoriteSpace({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SidebarSectionsBloc()
            ..add(SidebarSectionsEvent.initial(userProfile, workspaceId)),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        ),
      ],
      child: BlocListener<UserWorkspaceBloc, UserWorkspaceState>(
        listener: (context, state) =>
            context.read<FavoriteBloc>().add(const FavoriteEvent.initial()),
        child: MultiBlocListener(
          listeners: [
            BlocListener<SidebarSectionsBloc, SidebarSectionsState>(
              listenWhen: (p, c) =>
                  p.lastCreatedRootView?.id != c.lastCreatedRootView?.id,
              listener: (context, state) =>
                  context.pushView(state.lastCreatedRootView!),
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
              return _FavoriteViews(favoriteViews: favoriteState.views);
            },
          ),
        ),
      ),
    );
  }
}

class _FavoriteViews extends StatelessWidget {
  const _FavoriteViews({
    required this.favoriteViews,
  });

  final List<SectionViewPB> favoriteViews;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.separated(
        key: const PageStorageKey('recent_views_page_storage_key'),
        padding: const EdgeInsets.symmetric(
          horizontal: HomeSpaceViewSizes.mHorizontalPadding,
          vertical: HomeSpaceViewSizes.mVerticalPadding,
        ),
        itemBuilder: (context, index) {
          final view = favoriteViews[index];
          return SizedBox(
            key: ValueKey(view.item.id),
            height: 136,
            child: MobileViewCard(
              key: ValueKey(view.item.id),
              view: view.item,
              timestamp: view.timestamp,
              type: MobileViewCardType.favorite,
            ),
          );
        },
        separatorBuilder: (context, index) => const HSpace(8),
        itemCount: favoriteViews.length,
      ),
    );
  }
}
