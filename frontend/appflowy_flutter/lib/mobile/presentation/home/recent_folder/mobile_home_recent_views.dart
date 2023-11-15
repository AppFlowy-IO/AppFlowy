import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/recent_folder/mobile_recent_view.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class MobileRecentFolder extends StatefulWidget {
  const MobileRecentFolder({super.key});

  @override
  State<MobileRecentFolder> createState() => _MobileRecentFolderState();
}

class _MobileRecentFolderState extends State<MobileRecentFolder> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: getIt<MobileRouterRecord>().lastPushedRouter,
      builder: (context, value, child) {
        return FutureBuilder<Either<RepeatedViewPB, FlowyError>>(
          future: FolderEventReadRecentViews().send(),
          builder: (context, snapshot) {
            final recentViews = snapshot.data
                ?.fold<List<ViewPB>>(
                  (l) => l.items,
                  (r) => [],
                )
                // only keep the first 10 items.
                .reversed
                .take(10)
                .toList();

            if (recentViews == null || recentViews.isEmpty) {
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
        );
      },
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
    return SizedBox(
      height: 168,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FlowyText.semibold(
              LocaleKeys.sideBar_recent.tr(),
              fontSize: 20.0,
            ),
          ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const HSpace(8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: recentViews.length,
              itemBuilder: (context, index) {
                return MobileRecentView(
                  view: recentViews[index],
                  height: 120,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
