import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

final GlobalKey _settingsDialogKey = GlobalKey();

Future<HotKeyItem?> openSettingsHotKey(BuildContext context) async {
  final userProfileOrFailure = await getIt<AuthService>().getUser();

  return userProfileOrFailure.fold(
    (userProfile) => HotKeyItem(
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
    ),
    (e) {
      Log.error('Failed to get user $e');
      return null;
    },
  );
}

class UserSettingButton extends StatelessWidget {
  const UserSettingButton({required this.userProfile, super.key});

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.settings_menu_open.tr(),
      child: IconButton(
        onPressed: () => showSettingsDialog(context, userProfile),
        icon: SizedBox.square(
          dimension: 20,
          child: FlowySvg(
            FlowySvgs.settings_m,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
    );
  }
}

void showSettingsDialog(
  BuildContext context,
  UserProfilePB userProfile,
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocProvider<DocumentAppearanceCubit>.value(
        key: _settingsDialogKey,
        value: BlocProvider.of<DocumentAppearanceCubit>(dialogContext),
        child: SettingsDialog(
          userProfile,
          didLogout: () async {
            // Pop the dialog using the dialog context
            Navigator.of(dialogContext).pop();
            await runAppFlowy();
          },
          dismissDialog: () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            } else {
              Log.warn("Can't pop dialog context");
            }
          },
          restartApp: () async {
            // Pop the dialog using the dialog context
            Navigator.of(dialogContext).pop();
            await runAppFlowy();
          },
        ),
      );
    },
  );
}
