import 'package:app_flowy/startup/startup.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show UserProfile;

class SettingsSettingsView extends StatelessWidget {
  final UserProfile user;
  SettingsSettingsView(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (context) => getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [UserNameInput()],
          ),
        ),
      ),
    );
  }
}

class UserNameInput extends StatefulWidget {
  const UserNameInput({
    Key? key,
  }) : super(key: key);

  @override
  State<UserNameInput> createState() => _UserNameInputState();
}

class _UserNameInputState extends State<UserNameInput> {
  @override
  Widget build(BuildContext context) {
    return TextField(
        decoration: const InputDecoration(
          labelText: 'Name',
        ),
        onSubmitted: (val) {
          context.read<MenuUserBloc>().add(MenuUserEvent.updateUserName(val));
          debugPrint("Value $val submitted");
        });
  }
}
