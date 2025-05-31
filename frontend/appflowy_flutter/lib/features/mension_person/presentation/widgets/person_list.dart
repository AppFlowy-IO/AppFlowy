import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/features/mension_person/data/models/member.dart';
import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'item_visibility_detector.dart';
import 'more_results_item.dart';

class PersonList extends StatelessWidget {
  const PersonList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<MentionBloc>().state,
        itemMap = context.read<MentionItemMap>();
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

    final id = LocaleKeys.document_mentionMenu_moreResults
        .tr(args: ['show more person']);
    void onShowMore() {
      if (!showMoreResult) return;
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
              backgroundColor: context.mentionItemBGColor,
              onTap: () {},
            ),
          );
        }),
        if (showMoreResult)
          MoreResultsItem(
            num: members.length - 4,
            onTap: onShowMore,
            id: id,
          ),
      ],
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
}
