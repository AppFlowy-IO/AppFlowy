import 'package:appflowy/mobile/presentation/home/shared/empty_placeholder.dart';
import 'package:appflowy/mobile/presentation/home/shared/mobile_page_card.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/recent/prelude.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MobileRecentSpace extends StatefulWidget {
  const MobileRecentSpace({super.key});

  @override
  State<MobileRecentSpace> createState() => _MobileRecentSpaceState();
}

class _MobileRecentSpaceState extends State<MobileRecentSpace>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (context) =>
          RecentViewsBloc()..add(const RecentViewsEvent.initial()),
      child: BlocBuilder<RecentViewsBloc, RecentViewsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SizedBox.shrink();
          }

          final recentViews = _filterRecentViews(state.views);

          if (recentViews.isEmpty) {
            return const Center(
              child: EmptySpacePlaceholder(type: MobilePageCardType.recent),
            );
          }

          return _RecentViews(recentViews: recentViews);
        },
      ),
    );
  }

  List<SectionViewPB> _filterRecentViews(List<SectionViewPB> recentViews) {
    final ids = <String>{};
    final filteredRecentViews = recentViews.toList();
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
    final borderColor = Theme.of(context).isLightMode
        ? const Color(0xFFE9E9EC)
        : const Color(0x1AFFFFFF);
    return SlidableAutoCloseBehavior(
      child: Scrollbar(
        child: ListView.separated(
          key: const PageStorageKey('recent_views_page_storage_key'),
          padding: EdgeInsets.only(
            left: HomeSpaceViewSizes.mHorizontalPadding,
            right: HomeSpaceViewSizes.mHorizontalPadding,
            bottom: HomeSpaceViewSizes.mVerticalPadding +
                MediaQuery.of(context).padding.bottom,
          ),
          itemBuilder: (context, index) {
            final sectionView = recentViews[index];
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
                key: ValueKey(sectionView.item.id),
                view: sectionView.item,
                timestamp: sectionView.timestamp,
                type: MobilePageCardType.recent,
              ),
            );
          },
          separatorBuilder: (context, index) => const HSpace(8),
          itemCount: recentViews.length,
        ),
      ),
    );
  }
}
