import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuUser extends MenuItem {
  final UserDetail user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (context) =>
          getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(children: [
          _renderAvatar(context),
          const HSpace(10),
          _renderUserName(context),
          const HSpace(10),
          _renderDropButton(context),
        ]),
      ),
    );
  }

  Widget _renderAvatar(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const Image(image: AssetImage('assets/images/avatar.jpg')),
      ),
    );
  }

  Widget _renderUserName(BuildContext context) {
    String name = context.read<MenuUserBloc>().state.user.name;
    if (name.isEmpty) {
      name = context.read<MenuUserBloc>().state.user.email;
    }
    return Flexible(
      child: Text(
        name,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _renderDropButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_drop_down),
      alignment: Alignment.center,
      padding: EdgeInsets.zero,
      onPressed: () {},
    );
  }

  @override
  MenuItemType get type => MenuItemType.userProfile;
}
