import 'dart:convert';
import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/debounce.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const defaultUserAvatar = '1F600';
const _iconSize = Size(60, 60);

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
              _renderCurrentIcon(context),
              const VSpace(20),
              _renderCurrentOpenaiKey(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderUserNameInput(BuildContext context) {
    final String name = context.read<SettingsUserViewBloc>().state.userProfile.name;
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

  Widget _renderCurrentOpenaiKey(BuildContext context) {
    final String openAIKey =
        context.read<SettingsUserViewBloc>().state.userProfile.openaiKey;
    return _OpenaiKeyInput(openAIKey);
  }
}

@visibleForTesting
class UserNameInput extends StatefulWidget {
  final String name;

  const UserNameInput(
    this.name, {
    Key? key,
  }) : super(key: key);

  @override
  UserNameInputState createState() => UserNameInputState();
}

class UserNameInputState extends State<UserNameInput> {
  late TextEditingController _controller;

  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: LocaleKeys.settings_user_name.tr(),
        labelStyle: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.w500),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.onBackground),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      onChanged: (val) {
        if (_debounce?.isActive ?? false) {
          _debounce!.cancel();
        }

        _debounce = Timer(_debounceDuration, () {
          context
              .read<SettingsUserViewBloc>()
              .add(SettingsUserEvent.updateUserName(val));
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _OpenaiKeyInput extends StatefulWidget {
  final String openAIKey;
  const _OpenaiKeyInput(
    this.openAIKey, {
    Key? key,
  }) : super(key: key);

  @override
  State<_OpenaiKeyInput> createState() => _OpenaiKeyInputState();
}

class _OpenaiKeyInputState extends State<_OpenaiKeyInput> {
  bool visible = false;
  final textEditingController = TextEditingController();
  final debounce = Debounce();

  @override
  void initState() {
    super.initState();

    textEditingController.text = widget.openAIKey;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      obscureText: !visible,
      decoration: InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.onBackground),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        labelText: 'OpenAI Key',
        labelStyle: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.w500),
        hintText: LocaleKeys.settings_user_pleaseInputYourOpenAIKey.tr(),
        suffixIcon: FlowyIconButton(
          width: 40,
          height: 40,
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              visible = !visible;
            });
          },
        ),
      ),
      onChanged: (value) {
        debounce.call(() {
          context
              .read<SettingsUserViewBloc>()
              .add(SettingsUserEvent.updateUserOpenAIKey(value));
        });
      },
    );
  }

  @override
  void dispose() {
    debounce.dispose();
    super.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.settings_user_icon.tr(),
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
        ),
        InkWell(
          borderRadius: Corners.s6Border,
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return SimpleDialog(
                  title: FlowyText.medium(
                    LocaleKeys.settings_user_selectAnIcon.tr(),
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
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 5, 5, 5),
            child: svgWidget(
              'emoji/$iconUrl',
              size: _iconSize,
            ),
          ),
        ),
      ],
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
        .where(
          (String key) =>
              key.startsWith('assets/images/emoji/') && key.endsWith('.svg'),
        )
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
    return InkWell(
      borderRadius: Corners.s6Border,
      hoverColor: Theme.of(context).colorScheme.tertiaryContainer,
      onTap: () {
        setIcon(iconUrl);
      },
      child: svgWidget('emoji/$iconUrl', size: _iconSize),
    );
  }
}
