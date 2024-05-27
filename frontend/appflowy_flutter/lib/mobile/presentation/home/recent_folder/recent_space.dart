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

  List<SectionViewPB> _filterRecentViews(List<SectionViewPB> recentViews) {
    final ids = <String>{};
    final filteredRecentViews = recentViews.reversed.toList();
    filteredRecentViews.retainWhere((e) => ids.add(e.item.id));
    return filteredRecentViews;
  }
}

class _RecentViews extends StatelessWidget {
  const _RecentViews({
    required this.recentViews,
  });

  final List<SectionViewPB> recentViews;

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
          final sectionView = recentViews[index];
          return SizedBox(
            height: 136,
            child: MobileRecentViewV2(sectionView: sectionView),
          );
        },
        separatorBuilder: (context, index) => const HSpace(8),
        itemCount: recentViews.length,
      ),
    );
  }
}
