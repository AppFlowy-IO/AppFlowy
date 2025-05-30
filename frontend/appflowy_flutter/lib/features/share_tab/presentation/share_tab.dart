import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/logic/share_with_user_bloc.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/copy_link_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/people_with_access_section.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/share_with_user_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:collection/collection.dart';
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

        final currentUserRole = state.users
            .firstWhereOrNull(
              (user) => user.email == state.currentUser?.email,
            )
            ?.role;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // share page with user by email
            // hide this when the user is guest
            if (currentUserRole != ShareRole.guest) ...[
              VSpace(theme.spacing.l),
              ShareWithUserWidget(
                controller: controller,
                onInvite: (emails) => _onSharePageWithUser(
                  context,
                  emails: emails,
                  accessLevel: ShareAccessLevel.readOnly,
                ),
              ),
            ],

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
        context.read<ShareWithUserBloc>().add(
              ShareWithUserEvent.updateAccessLevel(
                email: user.email,
                accessLevel: accessLevel,
              ),
            );
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
        String message;
        switch (error.code) {
          case ErrorCode.InvalidGuest:
            message = 'The email is already in the list';
            break;
          case ErrorCode.FreePlanGuestLimitExceeded:
            message = 'Please upgrade to a Pro plan to invite more guests';
            break;
          case ErrorCode.PaidPlanGuestLimitExceeded:
            message = 'You have reached the maximum number of guests';
            break;
          default:
            message = error.msg;
        }
        showToastNotification(
          message: message,
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
