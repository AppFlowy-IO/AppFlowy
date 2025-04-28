import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
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
    final theme = AppFlowyTheme.of(context);
    final commandPaletteState = context.read<CommandPaletteBloc>().state;

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
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VSpace(16),
                Text(
                  LocaleKeys.sideBar_recent.tr(),
                  style: theme.textStyle.body
                      .enhanced(color: theme.textColorScheme.secondary),
                ),
                const VSpace(4),
                Column(
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
            ),
          );
        },
      ),
    );
  }
}

class MobileSearchResultList extends StatefulWidget {
  const MobileSearchResultList({super.key});

  @override
  State<MobileSearchResultList> createState() => _MobileSearchResultListState();
}

class _MobileSearchResultListState extends State<MobileSearchResultList> {
  late final SearchResultListBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = SearchResultListBloc();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<CommandPaletteBloc>().state,
        theme = AppFlowyTheme.of(context);
    final isSearching = state.searching,
        items = state.combinedResponseItems.values.toList(),
        hasData = items.isNotEmpty;
    if (isSearching && !hasData) {
      return Center(child: CircularProgressIndicator.adaptive());
    } else if (!hasData) {
      return buildNoResult(state.query ?? '');
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VSpace(16),
          Text(
            LocaleKeys.commandPalette_bestMatches.tr(),
            style: theme.textStyle.body
                .enhanced(color: theme.textColorScheme.secondary),
          ),
          const VSpace(4),
          Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final view = await ViewBackendService.getView(item.id)
                      .fold((s) => s, (s) => null);
                  if (view != null && context.mounted) {
                    await _goToView(context, view);
                  } else {
                    Log.error(
                      'tapping search result, view not found: ${item.id}',
                    );
                  }
                },
                child: MobileSearchResultCell(
                  item: item,
                  query: state.query,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildNoResult(String query) {
    final theme = AppFlowyTheme.of(context),
        textColor = theme.textColorScheme.secondary;
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
