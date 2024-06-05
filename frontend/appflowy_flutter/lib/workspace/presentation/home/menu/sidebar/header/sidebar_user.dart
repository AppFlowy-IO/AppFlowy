import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// keep this widget in case we need to roll back (lucas.xu)
class SidebarUser extends StatelessWidget {
  const SidebarUser({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (_) =>
          MenuUserBloc(userProfile)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          children: [
            const HSpace(4),
            UserAvatar(
              iconUrl: state.userProfile.iconUrl,
              name: state.userProfile.name,
              size: 24.0,
              fontSize: 16.0,
              decoration: ShapeDecoration(
                color: const Color(0xFFFBE8FB),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 0.50, color: Color(0x19171717)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const HSpace(8),
            Expanded(child: _buildUserName(context, state)),
            UserSettingButton(userProfile: state.userProfile),
            const HSpace(8.0),
            const NotificationButton(),
            const HSpace(10.0),
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
      fontSize: 15.0,
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
