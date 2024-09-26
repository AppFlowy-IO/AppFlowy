import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/af_focus_manager.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final GlobalKey _settingsDialogKey = GlobalKey();

// show settings dialog with user profile for fully customized settings dialog
void showSettingsDialog(
  BuildContext context,
  UserProfilePB userProfile, [
  UserWorkspaceBloc? bloc,
  SettingsPage? initPage,
]) {
  AFFocusManager.of(context).notifyLoseFocus();
  showDialog(
    context: context,
    builder: (dialogContext) => MultiBlocProvider(
      key: _settingsDialogKey,
      providers: [
        BlocProvider<DocumentAppearanceCubit>.value(
          value: BlocProvider.of<DocumentAppearanceCubit>(dialogContext),
        ),
        BlocProvider.value(value: bloc ?? context.read<UserWorkspaceBloc>()),
      ],
      child: SettingsDialog(
        userProfile,
        initPage: initPage,
        didLogout: () async {
          // Pop the dialog using the dialog context
          Navigator.of(dialogContext).pop();
          await runAppFlowy();
        },
        dismissDialog: () {
          if (Navigator.of(dialogContext).canPop()) {
            return Navigator.of(dialogContext).pop();
          }
          Log.warn("Can't pop dialog context");
        },
        restartApp: () async {
          // Pop the dialog using the dialog context
          Navigator.of(dialogContext).pop();
          await runAppFlowy();
        },
      ),
    ),
  );
}

// show settings dialog without user profile for simple settings dialog
// only support
//  - language
//  - self-host
//  - support
void showSimpleSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => const SimpleSettingsDialog(),
  );
}
