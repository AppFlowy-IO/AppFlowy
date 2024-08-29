import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/account.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsAccountView extends StatefulWidget {
  const SettingsAccountView({
    super.key,
    required this.userProfile,
    required this.didLogin,
    required this.didLogout,
  });

  final UserProfilePB userProfile;

  // Called when the user signs in from the setting dialog
  final VoidCallback didLogin;

  // Called when the user logout in the setting dialog
  final VoidCallback didLogout;

  @override
  State<SettingsAccountView> createState() => _SettingsAccountViewState();
}

class _SettingsAccountViewState extends State<SettingsAccountView> {
  late String userName = widget.userProfile.name;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsUserViewBloc>(
      create: (context) =>
          getIt<SettingsUserViewBloc>(param1: widget.userProfile)
            ..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) {
          return SettingsBody(
            title: LocaleKeys.settings_accountPage_title.tr(),
            children: [
              // user profile
              SettingsCategory(
                title: LocaleKeys.settings_accountPage_general_title.tr(),
                children: [
                  AccountUserProfile(
                    name: userName,
                    iconUrl: state.userProfile.iconUrl,
                    onSave: (newName) {
                      // Pseudo change the name to update the UI before the backend
                      // processes the request. This is to give the user a sense of
                      // immediate feedback, and avoid UI flickering.
                      setState(() => userName = newName);
                      context
                          .read<SettingsUserViewBloc>()
                          .add(SettingsUserEvent.updateUserName(newName));
                    },
                  ),
                ],
              ),

              // user email
              // Only show email if the user is authenticated and not using local auth
              if (isAuthEnabled &&
                  state.userProfile.authenticator != AuthenticatorPB.Local) ...[
                SettingsCategory(
                  title: LocaleKeys.settings_accountPage_email_title.tr(),
                  children: [
                    FlowyText.regular(state.userProfile.email),
                  ],
                ),
              ],

              // user sign in/out
              SettingsCategory(
                title: LocaleKeys.settings_accountPage_login_title.tr(),
                children: [
                  AccountSignInOutButton(
                    userProfile: state.userProfile,
                    onAction:
                        state.userProfile.authenticator == AuthenticatorPB.Local
                            ? widget.didLogin
                            : widget.didLogout,
                    signIn: state.userProfile.authenticator ==
                        AuthenticatorPB.Local,
                  ),
                ],
              ),

              // user deletion
              const AccountDeletionButton(),
            ],
          );
        },
      ),
    );
  }
}
