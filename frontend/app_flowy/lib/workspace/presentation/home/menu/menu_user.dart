import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:app_flowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class MenuUser extends StatelessWidget {
  final UserProfile user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (context) => getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          children: [
            _renderAvatar(context),
            const HSpace(10),
            _renderUserName(context),
            const Spacer(),
            _renderSettingsButton(context),
            //ToDo: when the user is allowed to create another workspace,
            //we get the below block back
            //_renderDropButton(context),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
      ),
    );
  }

  Widget _renderAvatar(BuildContext context) {
    return const SizedBox(
      width: 25,
      height: 25,
      child: ClipRRect(
          borderRadius: Corners.s5Border,
          child: CircleAvatar(
            backgroundColor: Color.fromRGBO(132, 39, 224, 1.0),
            child: Text(
              'M',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
          )),
    );
  }

  Widget _renderUserName(BuildContext context) {
    String name = context.read<MenuUserBloc>().state.userProfile.name;
    if (name.isEmpty) {
      name = context.read<MenuUserBloc>().state.userProfile.email;
    }
    return FlowyText(name, fontSize: 12);
  }

  Widget _renderSettingsButton(BuildContext context) {
    final theme = context.watch<AppTheme>();
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
          child: svgWidget("home/settings", color: theme.iconColor),
        ),
      ),
    );
  }
  //ToDo: when the user is allowed to create another workspace,
  //we get the below block back
  // Widget _renderDropButton(BuildContext context) {
  //   return FlowyDropdownButton(
  //     onPressed: () {
  //       debugPrint('show user profile');
  //     },
  //   );
  // }
}
