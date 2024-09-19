import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/af_focus_manager.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:universal_platform/universal_platform.dart';

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
          UniversalPlatform.isMacOS ? KeyModifier.meta : KeyModifier.control,
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

class UserSettingButton extends StatefulWidget {
  const UserSettingButton({
    super.key,
    required this.userProfile,
    this.isHover = false,
  });

  final UserProfilePB userProfile;
  final bool isHover;

  @override
  State<UserSettingButton> createState() => _UserSettingButtonState();
}

class _UserSettingButtonState extends State<UserSettingButton> {
  late UserWorkspaceBloc _userWorkspaceBloc;

  @override
  void initState() {
    super.initState();
    _userWorkspaceBloc = context.read<UserWorkspaceBloc>();
  }

  @override
  void didChangeDependencies() {
    _userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24.0,
      child: FlowyTooltip(
        message: LocaleKeys.settings_menu_open.tr(),
        child: FlowyButton(
          onTap: () => showSettingsDialog(
            context,
            widget.userProfile,
            _userWorkspaceBloc,
          ),
          margin: EdgeInsets.zero,
          text: FlowySvg(
            FlowySvgs.settings_s,
            color:
                widget.isHover ? Theme.of(context).colorScheme.onSurface : null,
            opacity: 0.7,
          ),
        ),
      ),
    );
  }
}

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
