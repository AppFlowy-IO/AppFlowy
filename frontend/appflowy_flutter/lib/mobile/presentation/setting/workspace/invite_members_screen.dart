import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';
import 'package:toastification/toastification.dart';

import 'member_list.dart';

class InviteMembersScreen extends StatelessWidget {
  const InviteMembersScreen({
    super.key,
  });

  static const routeName = '/invite_member';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlowyAppBar(
        titleText: LocaleKeys.settings_appearance_members_label.tr(),
      ),
      body: const _InviteMemberPage(),
    );
  }
}

class _InviteMemberPage extends StatefulWidget {
  const _InviteMemberPage();

  @override
  State<_InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<_InviteMemberPage> {
  final emailController = TextEditingController();
  late final Future<UserProfilePB?> userProfile;

  @override
  void initState() {
    super.initState();
    userProfile = UserBackendService.getCurrentUserProfile().fold(
      (s) => s,
      (f) => null,
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: userProfile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _buildError(context);
        }

        final userProfile = snapshot.data!;

        return BlocProvider<WorkspaceMemberBloc>(
          create: (context) => WorkspaceMemberBloc(userProfile: userProfile)
            ..add(const WorkspaceMemberEvent.initial()),
          child: BlocConsumer<WorkspaceMemberBloc, WorkspaceMemberState>(
            listener: _onListener,
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildInviteMemberArea(context),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    child: FlowyDivider(),
                  ),
                  if (state.members.isNotEmpty)
                    MobileMemberList(
                      members: state.members,
                      userProfile: userProfile,
                      myRole: state.myRole,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInviteMemberArea(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          autofocus: true,
          controller: emailController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: LocaleKeys.settings_appearance_members_inviteHint.tr(),
          ),
        ),
        const VSpace(16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _inviteMember(context),
            child: Text(
              LocaleKeys.settings_appearance_members_sendInvite.tr(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowyText.medium(
              LocaleKeys.settings_appearance_members_workspaceMembersError.tr(),
              fontSize: 18.0,
              textAlign: TextAlign.center,
            ),
            const VSpace(8.0),
            FlowyText.regular(
              LocaleKeys
                  .settings_appearance_members_workspaceMembersErrorDescription
                  .tr(),
              fontSize: 17.0,
              maxLines: 10,
              textAlign: TextAlign.center,
              lineHeight: 1.3,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    );
  }

  void _onListener(BuildContext context, WorkspaceMemberState state) {
    final actionResult = state.actionResult;
    if (actionResult == null) {
      return;
    }

    final actionType = actionResult.actionType;
    final result = actionResult.result;

    // only show the result dialog when the action is WorkspaceMemberActionType.add
    if (actionType == WorkspaceMemberActionType.add) {
      result.fold(
        (s) {
          showToastNotification(
            context,
            message:
                LocaleKeys.settings_appearance_members_addMemberSuccess.tr(),
          );
        },
        (f) {
          Log.error('add workspace member failed: $f');
          final message = f.code == ErrorCode.WorkspaceMemberLimitExceeded
              ? LocaleKeys.settings_appearance_members_memberLimitExceeded.tr()
              : LocaleKeys.settings_appearance_members_failedToAddMember.tr();
          showToastNotification(
            context,
            type: ToastificationType.error,
            message: message,
          );
        },
      );
    } else if (actionType == WorkspaceMemberActionType.invite) {
      result.fold(
        (s) {
          showToastNotification(
            context,
            message:
                LocaleKeys.settings_appearance_members_inviteMemberSuccess.tr(),
          );
        },
        (f) {
          Log.error('invite workspace member failed: $f');
          final message = f.code == ErrorCode.WorkspaceMemberLimitExceeded
              ? LocaleKeys.settings_appearance_members_inviteFailedMemberLimit
                  .tr()
              : LocaleKeys.settings_appearance_members_failedToInviteMember
                  .tr();
          showToastNotification(
            context,
            type: ToastificationType.error,
            message: message,
          );
        },
      );
    } else if (actionType == WorkspaceMemberActionType.remove) {
      result.fold(
        (s) {
          showToastNotification(
            context,
            message: LocaleKeys
                .settings_appearance_members_removeFromWorkspaceSuccess
                .tr(),
          );
        },
        (f) {
          showToastNotification(
            context,
            type: ToastificationType.error,
            message: LocaleKeys
                .settings_appearance_members_removeFromWorkspaceFailed
                .tr(),
          );
        },
      );
    }
  }

  void _inviteMember(BuildContext context) {
    final email = emailController.text;
    if (!isEmail(email)) {
      return showToastNotification(
        context,
        message: LocaleKeys.settings_appearance_members_emailInvalidError.tr(),
      );
    }
    context
        .read<WorkspaceMemberBloc>()
        .add(WorkspaceMemberEvent.inviteWorkspaceMember(email));
    // clear the email field after inviting
    emailController.clear();
  }
}
