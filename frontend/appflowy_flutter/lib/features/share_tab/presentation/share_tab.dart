import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/share_tab/logic/share_with_user_bloc.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/copy_link_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/people_with_access_section.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/share_with_user_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareTab extends StatefulWidget {
  const ShareTab({
    super.key,
    required this.workspaceId,
    required this.pageId,
  });

  final String workspaceId;
  final String pageId;

  @override
  State<ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends State<ShareTab> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocConsumer<ShareWithUserBloc, ShareWithUserState>(
      listener: (context, state) {
        _onListenShareWithUserState(context, state);
      },
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
              controller: controller,
              onInvite: (emails) => _onSharePageWithUser(
                context,
                emails: emails,
                accessLevel: ShareAccessLevel.readOnly,
              ),
            ),

            // shared users

            if (state.users.isNotEmpty) ...[
              VSpace(theme.spacing.l),
              PeopleWithAccessSection(
                currentUserEmail: state.currentUser?.email ?? '',
                users: state.users,
                callbacks: _buildPeopleWithAccessSectionCallbacks(context),
              ),
            ],

            // general access
            // enable it when the backend support general access features.
            // VSpace(theme.spacing.m),
            // GeneralAccessSection(),

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
        context.read<ShareWithUserBloc>().add(
              ShareWithUserEvent.turnIntoMember(email: user.email),
            );
      },
      onRemoveAccess: (user) {
        context.read<ShareWithUserBloc>().add(
              ShareWithUserEvent.remove(emails: [user.email]),
            );
      },
    );
  }

  void _onListenShareWithUserState(
    BuildContext context,
    ShareWithUserState state,
  ) {
    final shareResult = state.shareResult;
    if (shareResult != null) {
      shareResult.fold((success) {
        // clear the controller to avoid showing the previous emails
        controller.clear();

        showToastNotification(
          message: 'Invitation sent',
        );
      }, (error) {
        // TODO: handle the limiation error
        showToastNotification(
          message: error.msg,
          type: ToastificationType.error,
        );
      });
    }

    final removeResult = state.removeResult;
    if (removeResult != null) {
      removeResult.fold((success) {
        showToastNotification(
          message: 'Removed guest successfully',
        );
      }, (error) {
        showToastNotification(
          message: error.msg,
          type: ToastificationType.error,
        );
      });
    }

    final updateAccessLevelResult = state.updateAccessLevelResult;
    if (updateAccessLevelResult != null) {
      updateAccessLevelResult.fold((success) {
        showToastNotification(
          message: 'Updated access level successfully',
        );
      }, (error) {
        showToastNotification(
          message: error.msg,
          type: ToastificationType.error,
        );
      });
    }
  }
}
