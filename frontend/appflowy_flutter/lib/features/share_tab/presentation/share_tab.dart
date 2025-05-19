import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/share_tab/logic/share_with_user_bloc.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/copy_link_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/general_access_section.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/people_with_acess_section.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/share_with_user_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareTab extends StatelessWidget {
  const ShareTab({
    super.key,
    required this.workspaceId,
    required this.pageId,
  });

  final String workspaceId;
  final String pageId;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocBuilder<ShareWithUserBloc, ShareWithUserState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // share page with user by email
            VSpace(theme.spacing.l),
            ShareWithUserWidget(
              onInvite: (emails) => _onSharePageWithUser(
                context,
                emails: emails,
                accessLevel: ShareAccessLevel.readOnly,
              ),
            ),

            // shared users
            VSpace(theme.spacing.l),
            state.errorMessage.isNotEmpty
                ? Center(child: Text(state.errorMessage))
                : PeopleWithAccessSection(
                    currentUserEmail: state.currentUser?.email ?? '',
                    users: state.users,
                    callbacks: _buildPeopleWithAccessSectionCallbacks(context),
                  ),

            // general access
            VSpace(theme.spacing.m),
            GeneralAccessSection(),

            // copy link
            VSpace(theme.spacing.l),
            const AFDivider(),
            VSpace(theme.spacing.xl),
            CopyLinkWidget(shareLink: state.shareLink),
            VSpace(theme.spacing.m),
          ],
        );
      },
    );
  }

  void _onSharePageWithUser(
    BuildContext context, {
    required List<String> emails,
    required ShareAccessLevel accessLevel,
  }) {
    context.read<ShareWithUserBloc>().add(
          ShareWithUserEvent.share(emails: emails, accessLevel: accessLevel),
        );
  }

  PeopleWithAccessSectionCallbacks _buildPeopleWithAccessSectionCallbacks(
    BuildContext context,
  ) {
    return PeopleWithAccessSectionCallbacks(
      onSelectAccessLevel: (user, accessLevel) {
        // do nothing. the event doesn't support in the backend yet
      },
      onTurnIntoMember: (user) {
        // do nothing. the event doesn't support in the backend yet
      },
      onRemoveAccess: (user) {
        context.read<ShareWithUserBloc>().add(
              ShareWithUserEvent.remove(emails: [user.email]),
            );
      },
    );
  }
}
