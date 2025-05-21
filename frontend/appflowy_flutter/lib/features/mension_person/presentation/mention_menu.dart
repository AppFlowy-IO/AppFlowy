import 'package:appflowy/features/mension_person/data/models/member.dart';
import 'package:appflowy/features/mension_person/data/repositories/mock_mention_repository.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          return AFMenu(
            width: 384,
            children: [personListSecontion(context)],
          );
        },
      ),
    );
  }

  AFMenuSection personListSecontion(BuildContext context) {
    final state = context.read<MentionBloc>().state;
    final members = state.members, showMoreMember = state.showMoreMember;
    final hasMoreMember = members.length > 4;
    final showMoreResult = !showMoreMember && hasMoreMember;
    List displayMembers = List.of(members);
    if(showMoreResult) {
      displayMembers = members.sublist(0, 4);
    }
    return AFMenuSection(
      title: LocaleKeys.document_mentionMenu_people.tr(),
      titleTrailing: sendNotificationSwitch(context),
      children: [
          ...List.generate(displayMembers.length, (index) {
            final member = displayMembers[index];
            return AFTextMenuItem(
              leading: buildAvatar(context, member),
              title: member.name,
              onTap: () {},
            );
          }),
          if(showMoreResult) AFTextMenuItem(
              
              title: LocaleKeys.document_mentionMenu_moreResults.tr(args: ['']),
              onTap: () {},
            )
      ],
    );
  }

  AFMenuSection pages(BuildContext context) {
    return AFMenuSection(
      title: LocaleKeys.document_mentionMenu_pages.tr(),
      children: [],
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
    return Row(
      children: [
        Text(
          LocaleKeys.document_mentionMenu_sendNotification.tr(),
          style: theme.textStyle.caption.standard(
            color: theme.textColorScheme.secondary,
          ),
        ),
        SizedBox(width: 4),
        Toggle(
          value: false,
          onChanged: (v) {},
        ),
      ],
    );
  }
}
