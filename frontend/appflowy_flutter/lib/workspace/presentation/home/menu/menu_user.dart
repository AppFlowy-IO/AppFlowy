import 'dart:math';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/menu/menu_user_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class MenuUser extends StatelessWidget {
  final UserProfilePB user;
  MenuUser(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MenuUserBloc>(
      create: (context) =>
          getIt<MenuUserBloc>(param1: user)..add(const MenuUserEvent.initial()),
      child: BlocBuilder<MenuUserBloc, MenuUserState>(
        builder: (context, state) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _renderAvatar(context),
            const HSpace(10),
            Expanded(
              child: _renderUserName(context),
            ),
            _renderSettingsButton(context),
            //ToDo: when the user is allowed to create another workspace,
            //we get the below block back
            //_renderDropButton(context),
          ],
        ),
      ),
    );
  }

  Widget _renderAvatar(BuildContext context) {
    String iconUrl = context.read<MenuUserBloc>().state.userProfile.iconUrl;
    if (iconUrl.isEmpty) {
      iconUrl = defaultUserAvatar;
      final String name = context.read<MenuUserBloc>().state.userProfile.name;
      final Color nameColor = _generateRandomNameColor(name);
      // Taking the first letters of the name components and limiting to 2 elements
      final nameInitials = name
          .split(' ')
          .map((element) => element[0].toUpperCase())
          .take(2)
          .join('');
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: nameColor,
          shape: BoxShape.circle,
        ),
        child: FlowyText.semibold(
          nameInitials,
          color: Colors.white,
          fontSize: nameInitials.length == 2 ? 12 : 14,
        ),
      );
    }
    return SizedBox(
      width: 25,
      height: 25,
      child: ClipRRect(
        borderRadius: Corners.s5Border,
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: svgWidget('emoji/$iconUrl'),
        ),
      ),
    );
  }

  Color _generateRandomNameColor(String name) {
    final hash = name.hashCode;
    final h = _normalizeHash(
      hash,
      0,
      360,
    );
    final s = _normalizeHash(
      hash,
      50,
      75,
    );
    final l = _normalizeHash(
      hash,
      25,
      60,
    );
    final color = _hslToColor(
      [h, s, l],
    );
    return color;
  }

  Color _hslToColor(List<int> hsl) {
    final h = hsl[0] / 360.0;
    final s = hsl[1] / 100.0;
    final l = hsl[2] / 100.0;
    late final double r, g, b;

    if (s == 0) {
      r = g = b = l;
    } else {
      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = _hueToRGB(p, q, h + 1 / 3);
      g = _hueToRGB(p, q, h);
      b = _hueToRGB(p, q, h - 1 / 3);
    }

    final red = (r * 255).round();
    final green = (g * 255).round();
    final blue = (b * 255).round();
    return Color.fromARGB(255, red, green, blue);
  }

  double _hueToRGB(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }

  int _normalizeHash(int hash, int min, int max) {
    return (hash % (max - min)) + min;
  }

  Widget _renderUserName(BuildContext context) {
    String name = context.read<MenuUserBloc>().state.userProfile.name;
    if (name.isEmpty) {
      name = context.read<MenuUserBloc>().state.userProfile.email;
    }
    return FlowyText.medium(
      name,
      overflow: TextOverflow.ellipsis,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }

  Widget _renderSettingsButton(BuildContext context) {
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
          child: svgWidget(
            "home/settings",
            color: Theme.of(context).colorScheme.tertiary,
          ),
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
