import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/af_focus_manager.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

final GlobalKey _settingsDialogKey = GlobalKey();

HotKeyItem openSettingsHotKey(
  BuildContext context,
  UserProfilePB userProfile,
) =>
    HotKeyItem(
      hotKey: HotKey(
        KeyCode.comma,
        scope: HotKeyScope.inapp,
        modifiers: [
          PlatformExtension.isMacOS ? KeyModifier.meta : KeyModifier.control,
        ],
      ),
      keyDownHandler: (_) {
        if (_settingsDialogKey.currentContext == null) {
          showSettingsDialog(context, userProfile);
        } else {
          Navigator.of(context, rootNavigator: true)
              .popUntil((route) => route.isFirst);
        }
      },
    );

class UserSettingButton extends StatelessWidget {
  const UserSettingButton({required this.userProfile, super.key});

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24.0,
      child: FlowyTooltip(
        message: LocaleKeys.settings_menu_open.tr(),
        child: FlowyButton(
          onTap: () => showSettingsDialog(context, userProfile),
          margin: EdgeInsets.zero,
          text: const FlowySvg(
            FlowySvgs.settings_s,
            opacity: 0.7,
          ),
        ),
      ),
    );
  }
}

void showSettingsDialog(BuildContext context, UserProfilePB userProfile) {
  AFFocusManager.of(context).notifyLoseFocus();
  showDialog(
    context: context,
    builder: (dialogContext) => MultiBlocProvider(
      key: _settingsDialogKey,
      providers: [
        BlocProvider<DocumentAppearanceCubit>.value(
          value: BlocProvider.of<DocumentAppearanceCubit>(dialogContext),
        ),
        BlocProvider.value(value: context.read<UserWorkspaceBloc>()),
      ],
      child: SettingsDialog(
        userProfile,
        workspaceId: context
            .read<UserWorkspaceBloc>()
            .state
            .currentWorkspace!
            .workspaceId,
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
