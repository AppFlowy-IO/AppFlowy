import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class MenuUser extends StatelessWidget {
  final UserProfilePB user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (context) =>
          getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _renderAvatar(context),
            const HSpace(10),
            Expanded(
              child: _renderUserName(context),
            ),
            _renderSettingsButton(context),
            //ToDo: when the user is allowed to create another workspace,
            //we get the below block back
            //_renderDropButton(context),
          ],
        ),
      ),
    );
  }

  Widget _renderAvatar(BuildContext context) {
    String iconUrl = context.read<MenuUserBloc>().state.userProfile.iconUrl;
    if (iconUrl.isEmpty) {
      iconUrl = defaultUserAvatar;
      final String name =
          userName(context.read<MenuUserBloc>().state.userProfile);
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
    return SizedBox(
      width: 25,
      height: 25,
      child: ClipRRect(
        borderRadius: Corners.s5Border,
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: svgWidget('emoji/$iconUrl'),
        ),
      ),
    );
  }

  Widget _renderUserName(BuildContext context) {
    final String name = userName(context.read<MenuUserBloc>().state.userProfile);
    return FlowyText.medium(
      name,
      overflow: TextOverflow.ellipsis,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }

  Widget _renderSettingsButton(BuildContext context) {
    final userProfile = context.read<MenuUserBloc>().state.userProfile;
    return Tooltip(
      message: LocaleKeys.settings_menu_open.tr(),
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return SettingsDialog(userProfile);
            },
          );
        },
        icon: SizedBox.square(
          dimension: 20,
          child: svgWidget(
            "home/settings",
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
    );
  }

  /// Return the user name, if the user name is empty, return the default user name.
  String userName(UserProfilePB userProfile) {
    String name = userProfile.name;
    if (name.isEmpty) {
      name = LocaleKeys.defaultUsername.tr();
    }
    return name;
  }
}
