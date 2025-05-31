import 'package:appflowy/features/mension_person/data/models/member.dart';
import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/data/repositories/mock_mention_repository.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_icon.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/item_visibility_detector.dart';
import 'widgets/mention_menu_scroller.dart';
import 'widgets/mention_menu_shortcuts.dart';

class MentionMenu extends StatelessWidget {
  const MentionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return BlocProvider(
      create: (_) => MentionBloc(MockMentionRepository(), workspaceId),
      child: BlocBuilder<MentionBloc, MentionState>(
        builder: (context, state) {
          final itemMap = MentionItemMap();
          final personList = personListSecontion(context, itemMap);
          final pageList = pages(context, itemMap);
          final dateReminder = dateAndReminder(context, itemMap);
          return MentionMenuScroller(
            builder: (_, controller) {
              return BlocListener<MentionBloc, MentionState>(
                listener: (context, state) {
                  if (!controller.hasClients || !context.mounted) return;
                  controller.jumpTo(0);
                },
                listenWhen: (previous, current) =>
                    previous.query != current.query,
                child: MentionMenuShortcuts(
                  scrollController: controller,
                  itemMap: itemMap,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 400),
                    child: AFMenu(
                      width: 400,
                      builder: (context, children) {
                        return SingleChildScrollView(
                          controller: controller,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        );
                      },
                      children: [
                        personList,
                        pageList,
                        dateReminder,
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  AFMenuSection personListSecontion(
    BuildContext context,
    MentionItemMap itemMap,
  ) {
    final state = context.read<MentionBloc>().state;
    final members = state.members, showMoreMember = state.showMoreMember;
    final hasMoreMember = members.length > 4;
    final showMoreResult = !showMoreMember && hasMoreMember;
    List<Member> displayMembers = List.of(members);
    if (showMoreResult) {
      displayMembers = members.sublist(0, 4);
    }

    for (final member in displayMembers) {
      itemMap.addToPerson(MentionMenuItem(id: member.id, onExecute: () {}));
    }

    final id =
        LocaleKeys.document_mentionMenu_moreResults.tr(args: ['addPerson']);
    void onShowMore() {
      context
          .read<MentionBloc>()
          .add(MentionEvent.showMoreMembers(members[4].id));
    }

    if (showMoreResult) {
      itemMap.addToPerson(MentionMenuItem(id: id, onExecute: onShowMore));
    }

    return AFMenuSection(
      title: LocaleKeys.document_mentionMenu_people.tr(),
      titleTrailing: sendNotificationSwitch(context),
      children: [
        ...List.generate(displayMembers.length, (index) {
          final member = displayMembers[index];
          return MentionMenuItenVisibilityDetector(
            id: member.id,
            child: AFTextMenuItem(
              leading: AFAvatar(url: member.avatarUrl, size: AFAvatarSize.s),
              selected: state.selectedId == member.id,
              title: member.name,
              subtitle: member.email,
              backgroundColor: backgroundColor,
              onTap: () {},
            ),
          );
        }),
        if (showMoreResult)
          moreResults(
            context: context,
            num: members.length - 4,
            onTap: onShowMore,
            id: id,
          ),
      ],
    );
  }

  Widget pages(BuildContext context, MentionItemMap itemMap) {
    final mentionState = context.read<MentionBloc>().state;
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
              .tr(args: ['addPpage']);
          void onShowMore() {
            context
                .read<MentionBloc>()
                .add(MentionEvent.showMorePages(displayedViews[4].id));
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
                    backgroundColor: backgroundColor,
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
                moreResults(
                  context: context,
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

  Widget dateAndReminder(BuildContext context, MentionItemMap itemMap) {
    final items = [
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateToday.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateTomorrow.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateYesterday.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_reminderTomorrow9Am.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_reminder1Week.tr(),
        onExecute: () {},
      ),
    ];

    final mentionState = context.read<MentionBloc>().state,
        query = mentionState.query;
    List<MentionMenuItem> filterItems = List.of(items);
    if (query.isNotEmpty) {
      filterItems = filterItems
          .where((item) => item.id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    if (filterItems.isEmpty) return const SizedBox.shrink();
    final children = List.generate(filterItems.length, (index) {
      final item = filterItems[index];
      itemMap.addToDateAndReminder(item);
      return MentionMenuItenVisibilityDetector(
        id: item.id,
        child: AFTextMenuItem(
          title: item.id,
          selected: context.read<MentionBloc>().state.selectedId == item.id,
          onTap: item.onExecute,
          backgroundColor: backgroundColor,
        ),
      );
    });

    return AFMenuSection(
      title: LocaleKeys.document_mentionMenu_dateAndReminder.tr(),
      children: children,
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
        leading: FlowySvg(
          FlowySvgs.mention_create_page_m,
          color: theme.iconColorScheme.primary,
        ),
        backgroundColor: backgroundColor,
        onTap: onTap,
      ),
    );
  }

  Widget moreResults({
    required BuildContext context,
    required int num,
    required VoidCallback onTap,
    required String id,
  }) {
    final state = context.read<MentionBloc>().state;

    final theme = AppFlowyTheme.of(context);
    return MentionMenuItenVisibilityDetector(
      id: id,
      child: AFTextMenuItem(
        selected: state.selectedId == id,
        title: LocaleKeys.document_mentionMenu_moreResults.tr(args: ['$num']),
        titleColor: theme.textColorScheme.tertiary,
        onTap: onTap,
        backgroundColor: backgroundColor,
      ),
    );
  }

  Widget buildAvatar(BuildContext context, Member member) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.borderRadius.m),
        border: Border.all(
          color: theme.borderColorScheme.primary,
        ),
      ),
      padding: EdgeInsets.all(theme.spacing.xs),
      child: const FlutterLogo(size: 18),
    );
  }

  Widget sendNotificationSwitch(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final bloc = context.read<MentionBloc>(), state = bloc.state;

    return Row(
      children: [
        Text(
          LocaleKeys.document_mentionMenu_sendNotification.tr(),
          style: theme.textStyle.caption
              .standard(color: theme.textColorScheme.secondary)
              .copyWith(letterSpacing: 0.1),
        ),
        SizedBox(width: 4),
        Toggle(
          value: state.sendNotification,
          style: ToggleStyle(width: 34, height: 18, thumbRadius: 17),
          padding: EdgeInsets.zero,
          inactiveBackgroundColor: theme.fillColorScheme.secondary,
          onChanged: (v) {
            bloc.add(MentionEvent.toggleSendNotification());
          },
        ),
      ],
    );
  }

  Color backgroundColor(
    BuildContext context,
    bool isHovering,
    bool selected,
    bool disabled,
  ) {
    return isHovering || selected
        ? AppFlowyTheme.of(context).fillColorScheme.contentHover
        : AppFlowyTheme.of(context).fillColorScheme.content;
  }
}
