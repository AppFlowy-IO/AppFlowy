import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class SidebarUser extends StatelessWidget {
  const SidebarUser({
    super.key,
    required this.user,
    required this.views,
  });

  final UserProfilePB user;
  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (context) => MenuUserBloc(user)
        ..add(
          const MenuUserEvent.initial(),
        ),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(
              iconUrl: state.userProfile.iconUrl,
              name: state.userProfile.name,
            ),
            const HSpace(10),
            Expanded(
              child: _buildUserName(context, state),
            ),
            _buildSettingsButton(context, state),
            const HSpace(4),
            NotificationButton(views: views),
          ],
        ),
      ),
    );
  }

  Widget _buildUserName(BuildContext context, MenuUserState state) {
    final String name = _userName(state.userProfile);
    return FlowyText.medium(
      name,
      overflow: TextOverflow.ellipsis,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }

  Widget _buildSettingsButton(BuildContext context, MenuUserState state) {
    final userProfile = state.userProfile;
    return FlowyTooltip(
      message: LocaleKeys.settings_menu_open.tr(),
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return BlocProvider<DocumentAppearanceCubit>.value(
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
        },
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

  /// Return the user name, if the user name is empty, return the default user name.
  String _userName(UserProfilePB userProfile) {
    String name = userProfile.name;
    if (name.isEmpty) {
      name = LocaleKeys.defaultUsername.tr();
    }
    return name;
  }
}
