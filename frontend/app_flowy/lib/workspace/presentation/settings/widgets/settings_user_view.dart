import 'package:app_flowy/startup/startup.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/application/user/settings_user_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dart:convert';

class SettingsUserView extends StatelessWidget {
  final UserProfilePB user;
  SettingsUserView(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsUserViewBloc>(
      create: (context) => getIt<SettingsUserViewBloc>(param1: user)..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_renderUserNameInput(context), const VSpace(20), const _CurrentIcon()],
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

class _CurrentIcon extends StatefulWidget {
  const _CurrentIcon({Key? key}) : super(key: key);

  @override
  State<_CurrentIcon> createState() => _CurrentIconState();
}

class _CurrentIconState extends State<_CurrentIcon> {
  String iconUrl = 'assets/images/emoji/page.svg';

  _setIcon(String path) {
    setState(() {
      iconUrl = path;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return SimpleDialog(
                    title: const Text('Select an Icon'),
                    children: <Widget>[SizedBox(height: 300, width: 300, child: IconGallery(_setIcon))]);
              },
            );
          },
          child: Column(children: <Widget>[
            const Align(alignment: Alignment.topLeft, child: Text("Icon")),
            Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(iconUrl),
            ),
          ])),
    );
  }
}

class IconGallery extends StatelessWidget {
  final Function setIcon;
  const IconGallery(this.setIcon, {Key? key}) : super(key: key);

  Future<List<String>> _initImages(BuildContext context) async {
    // >> To get paths you need these 2 lines
    final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    // >> To get paths you need these 2 lines

    final imagePaths =
        manifestMap.keys.where((String key) => key.startsWith('assets/images/emoji/') && key.endsWith('.svg')).toList();

    return imagePaths;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _initImages(context),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.hasData) {
          return GridView.count(
            primary: false,
            padding: const EdgeInsets.all(20),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            crossAxisCount: 5,
            children: (snapshot.data ?? []).map((String fileName) {
              return IconOption(fileName, 50.0, setIcon);
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
  final String fileName;
  final double size;
  final Function setIcon;

  IconOption(this.fileName, this.size, this.setIcon, {Key? key}) : super(key: ValueKey(fileName));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          debugPrint('$fileName is tapped');
          setIcon(fileName);
        },
        child: SvgPicture.asset(fileName),
      ),
    );
  }
}
