import 'package:app_flowy/startup/startup.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/application/user/settings_user_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show UserProfile;

class SettingsUserView extends StatelessWidget {
  final UserProfile user;
  SettingsUserView(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsUserViewBloc>(
      create: (context) => getIt<SettingsUserViewBloc>(param1: user)..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_renderUserNameInput(context)],
          ),
        ),
      ),
    );
  }

  Widget _renderUserNameInput(BuildContext context) {
    String name = context.read<SettingsUserViewBloc>().state.userProfile.name;
    return _UserNameInput(name);
  }
}

class _UserNameInput extends StatelessWidget {
  final String name;
  const _UserNameInput(
    this.name, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: TextEditingController()..text = name,
        decoration: const InputDecoration(
          labelText: 'Name',
        ),
        onSubmitted: (val) {
          context.read<SettingsUserViewBloc>().add(SettingsUserEvent.updateUserName(val));
        });
  }
}
