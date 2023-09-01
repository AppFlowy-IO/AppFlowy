import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
  });

  final UserProfilePB user;

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
            _buildAvatar(context, state),
            const HSpace(10),
            Expanded(
              child: _buildUserName(context, state),
            ),
            _buildSettingsButton(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, MenuUserState state) {
    String iconUrl = state.userProfile.iconUrl;
    if (iconUrl.isEmpty) {
      iconUrl = defaultUserAvatar;
      final String name = _userName(state.userProfile);
      final Color color = ColorGenerator().generateColorFromString(name);
      const initialsCount = 2;
      // Taking the first letters of the name components and limiting to 2 elements
      final nameInitials = name
          .split(' ')
          .where((element) => element.isNotEmpty)
          .take(initialsCount)
          .map((element) => element[0].toUpperCase())
          .join('');
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: FlowyText.semibold(
          nameInitials,
          color: Colors.white,
          fontSize: nameInitials.length == initialsCount ? 12 : 14,
        ),
      );
    }
    return SizedBox.square(
      dimension: 25,
      child: ClipRRect(
        borderRadius: Corners.s5Border,
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: FlowySvg(
            FlowySvgData('emoji/$iconUrl'),
            blendMode: null,
          ),
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
    return Tooltip(
      message: LocaleKeys.settings_menu_open.tr(),
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return BlocProvider<DocumentAppearanceCubit>.value(
                value: BlocProvider.of<DocumentAppearanceCubit>(context),
                child: SettingsDialog(
                  userProfile,
                  didLogout: () async {
                    // Pop the dialog using the dialog context
                    Navigator.of(dialogContext).pop();
                    await runAppFlowy();
                  },
                  dismissDialog: () => Navigator.of(context).pop(),
                  didOpenUser: () async {
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
