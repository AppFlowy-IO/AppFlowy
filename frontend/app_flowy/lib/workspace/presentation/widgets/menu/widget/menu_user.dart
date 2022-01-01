import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:app_flowy/workspace/presentation/theme/themeProvider.dart';
import 'package:provider/provider.dart';
//import 'package:flowy_infra_ui/style_widget/icon_button.dart';

class MenuUser extends StatelessWidget {
  final UserProfile user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return BlocProvider<MenuUserBloc>(
      create: (context) => getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          children: [
            _renderAvatar(context),
            const HSpace(10),
            _renderUserName(context),
            const HSpace(80),
            (themeProvider.isDarkMode ? _renderDarkMode(context) : _renderLightMode(context)),

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
                color: Colors.white,
              ),
            ),
          )),
    );
  }

  Widget _renderThemeToggle(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = context.watch<AppTheme>();
    return Switch.adaptive(
      value: themeProvider.isDarkMode,
      onChanged: (value) {
        final provider = Provider.of<ThemeProvider>(context, listen: false);
        provider.toggleTheme(value);
        print(themeProvider.isDarkMode);
      },
    );
    // return Material(
    //     // width: 25,
    //     // height: 25,
    //     // backgroundColor: Color.fromRGBO(132, 39, 224, 1.0),
    //     child: CircleAvatar(
    //   child: IconButton(
    //       icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
    //       color: (theme.shader1),
    //       onPressed: () {
    //         provider.toggleTheme(themeProvider.isDarkMode);
    //         print(themeProvider.isDarkMode);
    //         print(themeProvider.themeMode.name);
    //         print(theme.textColor);
    //       }),
    // ));
  }

  Widget _renderDarkMode(BuildContext context) {
    return Tooltip(
      message: "Set to Dark Mode",
      child: _renderThemeToggle(context),
    );
  }

  Widget _renderLightMode(BuildContext context) {
    return Tooltip(
      message: "Set to Light Mode",
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
