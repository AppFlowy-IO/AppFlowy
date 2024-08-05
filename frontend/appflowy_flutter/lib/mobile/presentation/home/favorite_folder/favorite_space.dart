import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/shared/empty_placeholder.dart';
import 'package:appflowy/mobile/presentation/home/shared/mobile_page_card.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileFavoriteSpace extends StatefulWidget {
  const MobileFavoriteSpace({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<MobileFavoriteSpace> createState() => _MobileFavoriteSpaceState();
}

class _MobileFavoriteSpaceState extends State<MobileFavoriteSpace>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SidebarSectionsBloc()
            ..add(
              SidebarSectionsEvent.initial(widget.userProfile, workspaceId),
            ),
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

              if (favoriteState.isLoading) {
                return const SizedBox.shrink();
              }

              if (favoriteState.views.isEmpty) {
                return const EmptySpacePlaceholder(
                  type: MobilePageCardType.favorite,
                );
              }

              return _FavoriteViews(
                favoriteViews: favoriteState.views.reversed.toList(),
              );
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
    final borderColor = Theme.of(context).isLightMode
        ? const Color(0xFFE9E9EC)
        : const Color(0x1AFFFFFF);
    return Scrollbar(
      child: ListView.separated(
        key: const PageStorageKey('favorite_views_page_storage_key'),
        padding: EdgeInsets.only(
          bottom: HomeSpaceViewSizes.mVerticalPadding +
              MediaQuery.of(context).padding.bottom,
        ),
        itemBuilder: (context, index) {
          final view = favoriteViews[index];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: 0.5,
                ),
              ),
            ),
            child: MobileViewPage(
              key: ValueKey(view.item.id),
              view: view.item,
              timestamp: view.timestamp,
              type: MobilePageCardType.favorite,
            ),
          );
        },
        separatorBuilder: (context, index) => const HSpace(8),
        itemCount: favoriteViews.length,
      ),
    );
  }
}
