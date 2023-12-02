import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/recent_folder/mobile_recent_view.dart';
import 'package:appflowy/workspace/application/recent/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileRecentFolder extends StatefulWidget {
  const MobileRecentFolder({super.key});

  @override
  State<MobileRecentFolder> createState() => _MobileRecentFolderState();
}

class _MobileRecentFolderState extends State<MobileRecentFolder> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecentViewsBloc()
        ..add(
          const RecentViewsEvent.initial(),
        ),
      child: BlocBuilder<RecentViewsBloc, RecentViewsState>(
        builder: (context, state) {
          final recentViews = state
              .views
              // only keep the first 10 items.
              .reversed
              .take(10)
              .toList();

          if (recentViews.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              _RecentViews(
                key: ValueKey(recentViews),
                // the recent views are in reverse order
                recentViews: recentViews,
              ),
              const VSpace(12.0),
            ],
          );
        },
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FlowyText.semibold(
            LocaleKeys.sideBar_recent.tr(),
            fontSize: 20.0,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: IntrinsicHeight(
            child: SeparatedRow(
              separatorBuilder: () => const HSpace(8),
              children: recentViews
                  .map(
                    (view) => SizedBox.square(
                      dimension: 148,
                      child: MobileRecentView(view: view),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
