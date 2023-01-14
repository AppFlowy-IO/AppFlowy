import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/application/user/settings_user_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra/image.dart';

import 'dart:convert';

const defaultUserAvatar = '1F600';

class SettingsUserView extends StatelessWidget {
  final UserProfilePB user;
  SettingsUserView(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsUserViewBloc>(
      create: (context) => getIt<SettingsUserViewBloc>(param1: user)
        ..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _renderUserNameInput(context),
              const VSpace(20),
              _renderCurrentIcon(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderUserNameInput(BuildContext context) {
    String name = context.read<SettingsUserViewBloc>().state.userProfile.name;
    return UserNameInput(name);
  }

  Widget _renderCurrentIcon(BuildContext context) {
    String iconUrl =
        context.read<SettingsUserViewBloc>().state.userProfile.iconUrl;
    if (iconUrl.isEmpty) {
      iconUrl = defaultUserAvatar;
    }
    return _CurrentIcon(iconUrl);
  }
}

@visibleForTesting
class UserNameInput extends StatelessWidget {
  final String name;
  const UserNameInput(
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
          context
              .read<SettingsUserViewBloc>()
              .add(SettingsUserEvent.updateUserName(val));
        });
  }
}

class _CurrentIcon extends StatelessWidget {
  final String iconUrl;
  const _CurrentIcon(this.iconUrl, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void setIcon(String iconUrl) {
      context
          .read<SettingsUserViewBloc>()
          .add(SettingsUserEvent.updateUserIcon(iconUrl));
      Navigator.of(context).pop();
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: FlowyText.medium(
                  'Select an Icon',
                  fontSize: FontSizes.s16,
                ),
                children: <Widget>[
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: IconGallery(setIcon),
                  )
                ],
              );
            },
          );
        },
        child: Column(
          children: <Widget>[
            const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Icon",
                  style: TextStyle(color: Colors.grey),
                )),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(5.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey)),
                child: svgWidget('emoji/$iconUrl', size: const Size(60, 60)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IconGallery extends StatelessWidget {
  final Function setIcon;
  const IconGallery(this.setIcon, {Key? key}) : super(key: key);

  Future<List<String>> _getIcons(BuildContext context) async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final iconUrls = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/images/emoji/') && key.endsWith('.svg'))
        .map((String key) => key.split('/').last.split('.').first)
        .toList();

    return iconUrls;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getIcons(context),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.hasData) {
          return GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 5,
            children: (snapshot.data ?? []).map((String iconUrl) {
              return IconOption(iconUrl, setIcon);
            }).toList(),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class IconOption extends StatelessWidget {
  final String iconUrl;
  final Function setIcon;

  IconOption(this.iconUrl, this.setIcon, {Key? key})
      : super(key: ValueKey(iconUrl));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          setIcon(iconUrl);
        },
        child: svgWidget('emoji/$iconUrl'),
      ),
    );
  }
}
