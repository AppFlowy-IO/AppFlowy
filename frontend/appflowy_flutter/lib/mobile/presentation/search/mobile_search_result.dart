import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mobile_search_cell.dart';

class MobileSearchResult extends StatelessWidget {
  const MobileSearchResult({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<CommandPaletteBloc>().state;
    final query = (state.query ?? '').trim();
    if (query.isEmpty) {
      return const MobileSearchRecentList();
    }
    return MobileSearchResultList();
  }
}

class MobileSearchRecentList extends StatelessWidget {
  const MobileSearchRecentList({super.key});

  @override
  Widget build(BuildContext context) {
    final commandPaletteState = context.read<CommandPaletteBloc>().state;
    final theme = AppFlowyTheme.of(context);
    final trashIdSet = commandPaletteState.trash.map((e) => e.id).toSet();
    return BlocProvider(
      create: (context) =>
          RecentViewsBloc()..add(const RecentViewsEvent.initial()),
      child: BlocBuilder<RecentViewsBloc, RecentViewsState>(
        builder: (context, state) {
          final List<ViewPB> recentViews = state.views
              .map((e) => e.item)
              .where((e) => !trashIdSet.contains(e.id))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const VSpace(16),
              Text(
                LocaleKeys.sideBar_recent.tr(),
                style: theme.textStyle.heading4
                    .enhanced(color: theme.textColorScheme.secondary)
                    .copyWith(
                      letterSpacing: 0.2,
                      height: 24 / 16,
                    ),
              ),
              const VSpace(4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(recentViews.length, (index) {
                  final view = recentViews[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goToView(context, view),
                    child: MobileSearchResultCell(
                      item: view.toSearchResultItem(),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MobileSearchResultList extends StatelessWidget {
  const MobileSearchResultList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<CommandPaletteBloc>().state,
        theme = AppFlowyTheme.of(context);
    final isSearching = state.searching, cachedViews = state.cachedViews;
    List<SearchResultItem> displayItems =
        state.combinedResponseItems.values.toList();
    if (cachedViews.isNotEmpty) {
      displayItems =
          displayItems.where((item) => cachedViews[item.id] != null).toList();
    }
    final hasData = displayItems.isNotEmpty;

    if (isSearching && !hasData) {
      return Center(child: CircularProgressIndicator.adaptive());
    } else if (!hasData) {
      return buildNoResult(state.query ?? '', theme);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const VSpace(16),
        Text(
          LocaleKeys.commandPalette_bestMatches.tr(),
          style: theme.textStyle.heading4
              .enhanced(color: theme.textColorScheme.secondary)
              .copyWith(
                letterSpacing: 0.2,
                height: 24 / 16,
              ),
        ),
        const VSpace(4),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = displayItems[index];
            final view = state.cachedViews[item.id];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                if (view != null && context.mounted) {
                  await _goToView(context, view);
                } else {
                  showToastNotification(
                    message: LocaleKeys.search_somethingWentWrong.tr(),
                    type: ToastificationType.error,
                  );
                  Log.error(
                    'tapping search result, view not found: ${item.id}',
                  );
                }
              },
              child: MobileSearchResultCell(
                item: item,
                view: view,
                query: state.query,
              ),
            );
          },
          separatorBuilder: (context, index) => AFDivider(),
          itemCount: displayItems.length,
        ),
      ],
    );
  }

  Widget buildNoResult(String query, AppFlowyThemeData theme) {
    final textColor = theme.textColorScheme.secondary;
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 140,
        child: Column(
          children: [
            const VSpace(48),
            FlowySvg(
              FlowySvgs.m_home_search_icon_m,
              color: theme.iconColorScheme.secondary,
              size: Size.square(24),
            ),
            const VSpace(12),
            Text(
              LocaleKeys.search_noResultForSearching.tr(),
              style: theme.textStyle.body.enhanced(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              textAlign: TextAlign.center,
              LocaleKeys.search_noResultForSearchingHint.tr(),
              style: theme.textStyle.caption.standard(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _goToView(BuildContext context, ViewPB view) async {
  await context.pushView(
    view,
    tabs: [
      PickerTabType.emoji,
      PickerTabType.icon,
      PickerTabType.custom,
    ].map((e) => e.name).toList(),
  );
}
