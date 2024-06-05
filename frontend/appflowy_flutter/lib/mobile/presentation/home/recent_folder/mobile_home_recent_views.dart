import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/recent_folder/mobile_recent_view.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/workspace/application/recent/prelude.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileRecentFolder extends StatefulWidget {
  const MobileRecentFolder({super.key});

  @override
  State<MobileRecentFolder> createState() => _MobileRecentFolderState();
}

class _MobileRecentFolderState extends State<MobileRecentFolder> {
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
            final ids = <String>{};

            List<ViewPB> recentViews =
                state.views.reversed.map((e) => e.item).toList();
            recentViews.retainWhere((element) => ids.add(element.id));

            // only keep the first 20 items.
            recentViews = recentViews.take(20).toList();

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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            child: FlowyText.semibold(
              LocaleKeys.sideBar_recent.tr(),
              fontSize: 20.0,
            ),
            onTap: () {
              showMobileBottomSheet(
                context,
                showDivider: false,
                showDragHandle: true,
                backgroundColor: AFThemeExtension.of(context).background,
                builder: (_) {
                  return Column(
                    children: [
                      FlowyOptionTile.text(
                        text: LocaleKeys.button_clear.tr(),
                        leftIcon: FlowySvg(
                          FlowySvgs.m_delete_s,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textColor: Theme.of(context).colorScheme.error,
                        onTap: () {
                          context.read<RecentViewsBloc>().add(
                                RecentViewsEvent.removeRecentViews(
                                  recentViews.map((e) => e.id).toList(),
                                ),
                              );
                          context.pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            key: const PageStorageKey('recent_views_page_storage_key'),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final view = recentViews[index];
              return SizedBox.square(
                dimension: 148,
                child: MobileRecentView(view: view),
              );
            },
            separatorBuilder: (context, index) => const HSpace(8),
            itemCount: recentViews.length,
          ),
        ),
      ],
    );
  }
}
