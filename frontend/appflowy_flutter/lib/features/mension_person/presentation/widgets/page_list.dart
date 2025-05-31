import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'item_visibility_detector.dart';
import 'more_results_item.dart';

class PageList extends StatelessWidget {
  const PageList({super.key});

  @override
  Widget build(BuildContext context) {
    final mentionState = context.read<MentionBloc>().state,
        itemMap = context.read<MentionItemMap>();
    final showMorePage = mentionState.showMorePage, query = mentionState.query;

    return BlocProvider(
      create: (context) =>
          RecentViewsBloc()..add(const RecentViewsEvent.initial()),
      child: BlocBuilder<RecentViewsBloc, RecentViewsState>(
        builder: (context, state) {
          final recentViews = state.views.map((e) => e.item).toSet().toList();
          List<ViewPB> filterViews = List.of(recentViews);
          if (query.isNotEmpty) {
            filterViews = filterViews
                .where(
                  (view) => view.nameOrDefault
                      .toLowerCase()
                      .contains(query.toLowerCase()),
                )
                .toList();
          }
          final hasMorePage = filterViews.length > 4;
          List<ViewPB> displayedViews = List.of(filterViews);
          final showMoreResult = hasMorePage && !showMorePage;

          if (showMoreResult) {
            displayedViews = displayedViews.sublist(0, 4);
          }

          for (final view in displayedViews) {
            itemMap.addToPage(MentionMenuItem(id: view.id, onExecute: () {}));
          }

          final createPageId =
              LocaleKeys.inlineActions_createPage.tr(args: ['addPage']);
          void onPageCreated() {}
          itemMap.addToPage(
            MentionMenuItem(id: createPageId, onExecute: onPageCreated),
          );

          final showMoreId = LocaleKeys.document_mentionMenu_moreResults
              .tr(args: ['show more page']);
          void onShowMore() {
            if (!showMoreResult) return;
            context
                .read<MentionBloc>()
                .add(MentionEvent.showMorePages(filterViews[4].id));
          }

          if (showMoreResult) {
            itemMap.addToPage(
              MentionMenuItem(id: showMoreId, onExecute: onShowMore),
            );
          }

          return AFMenuSection(
            title: LocaleKeys.document_mentionMenu_pages.tr(),
            children: [
              ...List.generate(displayedViews.length, (index) {
                final view = displayedViews[index];
                return MentionMenuItenVisibilityDetector(
                  id: view.id,
                  child: AFTextMenuItem(
                    selected: mentionState.selectedId == view.id,
                    leading: SizedBox(
                      width: 20,
                      child: Center(child: view.buildIcon(context)),
                    ),
                    title: view.nameOrDefault,
                    backgroundColor: context.mentionItemBGColor,
                    onTap: () {},
                  ),
                );
              }),
              createPage(
                context: context,
                id: createPageId,
                onTap: onPageCreated,
              ),
              if (showMoreResult)
                MoreResultsItem(
                  num: recentViews.length - 4,
                  onTap: onShowMore,
                  id: showMoreId,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget createPage({
    required BuildContext context,
    required String id,
    required VoidCallback onTap,
  }) {
    final theme = AppFlowyTheme.of(context);
    final state = context.read<MentionBloc>().state, query = state.query;

    return MentionMenuItenVisibilityDetector(
      id: id,
      child: AFTextMenuItem(
        selected: state.selectedId == id,
        title: query.isNotEmpty
            ? LocaleKeys.inlineActions_createPage.tr(args: [query])
            : LocaleKeys.document_mentionMenu_createSubpage.tr(),
        leading: SizedBox.square(
          dimension: 24,
          child: Center(
            child: FlowySvg(
              FlowySvgs.mention_create_page_m,
              color: theme.iconColorScheme.primary,
              size: const Size.square(20.0),
            ),
          ),
        ),
        backgroundColor: context.mentionItemBGColor,
        onTap: onTap,
      ),
    );
  }
}
