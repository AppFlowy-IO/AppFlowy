import 'package:appflowy/mobile/presentation/home/recent_folder/mobile_recent_view.dart';
import 'package:appflowy/workspace/application/recent/prelude.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileRecentSpace extends StatelessWidget {
  const MobileRecentSpace({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RecentViewsBloc()..add(const RecentViewsEvent.initial()),
      child: BlocListener<UserWorkspaceBloc, UserWorkspaceState>(
        listenWhen: (previous, current) =>
            current.currentWorkspace != null &&
            previous.currentWorkspace?.workspaceId !=
                current.currentWorkspace!.workspaceId,
        listener: (context, state) => context
            .read<RecentViewsBloc>()
            .add(const RecentViewsEvent.resetRecentViews()),
        child: BlocBuilder<RecentViewsBloc, RecentViewsState>(
          builder: (context, state) {
            final recentViews = _filterRecentViews(state.views);

            if (recentViews.isEmpty) {
              return const SizedBox.shrink();
            }

            return _RecentViews(recentViews: recentViews);
          },
        ),
      ),
    );
  }

  List<ViewPB> _filterRecentViews(List<ViewPB> recentViews) {
    final ids = <String>{};
    final filteredRecentViews = recentViews.reversed.toList();
    filteredRecentViews.retainWhere((element) => ids.add(element.id));
    return filteredRecentViews;
  }
}

class _RecentViews extends StatelessWidget {
  const _RecentViews({
    super.key,
    required this.recentViews,
  });

  final List<ViewPB> recentViews;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const PageStorageKey('recent_views_page_storage_key'),
      padding: const EdgeInsets.symmetric(
        horizontal: HomeSpaceViewSizes.mHorizontalPadding,
        vertical: HomeSpaceViewSizes.mVerticalPadding,
      ),
      itemBuilder: (context, index) {
        final view = recentViews[index];
        return SizedBox.square(
          dimension: 148,
          child: MobileRecentView(view: view),
        );
      },
      separatorBuilder: (context, index) => const HSpace(8),
      itemCount: recentViews.length,
    );
  }
}
