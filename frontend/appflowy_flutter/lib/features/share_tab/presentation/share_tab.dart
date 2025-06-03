import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/data/models/shared_group.dart';
import 'package:appflowy/features/share_tab/logic/share_tab_bloc.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/copy_link_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/general_access_section.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/people_with_access_section.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/share_with_user_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
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
    required this.workspaceName,
    required this.workspaceIcon,
  });

  final String workspaceId;
  final String pageId;

  // these 2 values should be provided by the share tab bloc
  final String workspaceName;
  final String workspaceIcon;

  @override
  State<ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends State<ShareTab> {
  final TextEditingController controller = TextEditingController();
  late final ShareTabBloc shareTabBloc;

  @override
  void initState() {
    super.initState();

    shareTabBloc = context.read<ShareTabBloc>();
  }

  @override
  void dispose() {
    controller.dispose();
    shareTabBloc.add(ShareTabEvent.clearState());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocConsumer<ShareTabBloc, ShareTabState>(
      listener: (context, state) {
        _onListenShareWithUserState(context, state);
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox.shrink();
        }

        final currentUser = state.currentUser;
        final accessLevel = state.users
            .firstWhereOrNull(
              (user) => user.email == currentUser?.email,
            )
            ?.accessLevel;
        final isFullAccess = accessLevel == ShareAccessLevel.fullAccess;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // share page with user by email
            // only user with full access can invite others

            VSpace(theme.spacing.l),
            ShareWithUserWidget(
              controller: controller,
              disabled: !isFullAccess,
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
                isInPublicPage: state.sectionType == SharedSectionType.public,
                currentUserEmail: state.currentUser?.email ?? '',
                users: state.users,
                callbacks: _buildPeopleWithAccessSectionCallbacks(context),
              ),
            ],

            // general access
            if (state.sectionType == SharedSectionType.public) ...[
              VSpace(theme.spacing.m),
              GeneralAccessSection(
                group: SharedGroup(
                  id: widget.workspaceId,
                  name: widget.workspaceName,
                  icon: widget.workspaceIcon,
                ),
              ),
            ],

            // copy link
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
    context.read<ShareTabBloc>().add(
          ShareTabEvent.inviteUsers(emails: emails, accessLevel: accessLevel),
        );
  }

  PeopleWithAccessSectionCallbacks _buildPeopleWithAccessSectionCallbacks(
    BuildContext context,
  ) {
    return PeopleWithAccessSectionCallbacks(
      onSelectAccessLevel: (user, accessLevel) {
        context.read<ShareTabBloc>().add(
              ShareTabEvent.updateUserAccessLevel(
                email: user.email,
                accessLevel: accessLevel,
              ),
            );
      },
      onTurnIntoMember: (user) {
        context.read<ShareTabBloc>().add(
              ShareTabEvent.convertToMember(email: user.email),
            );
      },
      onRemoveAccess: (user) {
        // show a dialog to confirm the action when removing self access
        final theme = AppFlowyTheme.of(context);
        final shareTabBloc = context.read<ShareTabBloc>();
        final removingSelf =
            user.email == shareTabBloc.state.currentUser?.email;
        if (removingSelf) {
          showConfirmDialog(
            context: context,
            title: 'Remove your own access',
            titleStyle: theme.textStyle.body.standard(
              color: theme.textColorScheme.primary,
            ),
            description: '',
            style: ConfirmPopupStyle.cancelAndOk,
            confirmLabel: 'Remove',
            onConfirm: () {
              shareTabBloc.add(
                ShareTabEvent.removeUsers(emails: [user.email]),
              );
            },
          );
        } else {
          shareTabBloc.add(
            ShareTabEvent.removeUsers(emails: [user.email]),
          );
        }
      },
    );
  }

  void _onListenShareWithUserState(
    BuildContext context,
    ShareTabState state,
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

    final turnIntoMemberResult = state.turnIntoMemberResult;
    if (turnIntoMemberResult != null) {
      turnIntoMemberResult.fold((success) {
        showToastNotification(
          message: 'Turned into member successfully',
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
