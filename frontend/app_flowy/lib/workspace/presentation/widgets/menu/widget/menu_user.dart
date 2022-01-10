import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/workspace/presentation/theme/theme_model.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class MenuUser extends StatelessWidget {
  final UserProfile user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider<MenuUserBloc>(
      create: (context) => getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          children: [
            _renderAvatar(context),
            const HSpace(10),
            _renderUserName(context),
            const HSpace(80),
            (theme.isDark ? _renderLightMode(context) : _renderDarkMode(context)),

            //ToDo: when the user is allowed to create another workspace,
            //we get the below block back
            //_renderDropButton(context),
          ],
          mainAxisAlignment: MainAxisAlignment.start,
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

  Widget _renderThemeToggle(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return CircleAvatar(
      backgroundColor: theme.surface,
      child: IconButton(
          icon: Icon(theme.isDark ? Icons.dark_mode : Icons.light_mode),
          color: (theme.iconColor),
          onPressed: () {
            context.read<ThemeModel>().swapTheme();
          }),
    );
  }

  Widget _renderDarkMode(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.tooltip_darkMode.tr(),
      child: _renderThemeToggle(context),
    );
  }

  Widget _renderLightMode(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.tooltip_lightMode.tr(),
      child: _renderThemeToggle(context),
    );
  }

  Widget _renderUserName(BuildContext context) {
    String name = context.read<MenuUserBloc>().state.user.name;
    if (name.isEmpty) {
      name = context.read<MenuUserBloc>().state.user.email;
    }
    return Flexible(
      child: FlowyText(name, fontSize: 12),
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
