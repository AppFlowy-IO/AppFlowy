import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';

class MenuUser extends MenuItem {
  final UserProfile user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));
  @override
  MenuItemType get type => MenuItemType.userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (context) => getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          children: [
            _renderAvatar(context),
            const HSpace(12),
            _renderUserName(context),
            const HSpace(4),
            _renderDropButton(context),
          ],
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
      ),
    );
  }

  Widget _renderAvatar(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: ClipRRect(
        borderRadius: Corners.s5Border,
        child: Image(image: AssetImage('assets/images/avatar.jpg')),
      ),
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

  Widget _renderDropButton(BuildContext context) {
    return FlowyDropdownButton(
      onPressed: () {
        debugPrint('show user profile');
      },
    );
  }
}
