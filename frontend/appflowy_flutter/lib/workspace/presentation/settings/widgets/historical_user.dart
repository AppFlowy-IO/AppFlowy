import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoricalUserList extends StatelessWidget {
  final VoidCallback didOpenUser;
  const HistoricalUserList({required this.didOpenUser, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
      builder: (context, state) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowyText.medium(
                LocaleKeys.settings_menu_historicalUserList.tr(),
                fontSize: 13,
              ),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    final user = state.historicalUsers[index];
                    return HistoricalUserItem(
                      key: ValueKey(user.userId),
                      user: user,
                      isSelected: state.userProfile.id == user.userId,
                      didOpenUser: didOpenUser,
                    );
                  },
                  itemCount: state.historicalUsers.length,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class HistoricalUserItem extends StatelessWidget {
  final VoidCallback didOpenUser;
  final bool isSelected;
  final HistoricalUserPB user;
  const HistoricalUserItem({
    required this.user,
    required this.isSelected,
    required this.didOpenUser,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? const FlowySvg(name: "grid/checkmark") : null;
    final isDisabled = isSelected || user.authType != AuthTypePB.Local;
    final outputFormat = DateFormat('MM/dd/yyyy');
    final date =
        DateTime.fromMillisecondsSinceEpoch(user.lastTime.toInt() * 1000);
    final lastTime = outputFormat.format(date);
    final desc = "${user.userName}  ${user.authType}  $lastTime";
    final child = SizedBox(
      height: 30,
      child: FlowyButton(
        disable: isDisabled,
        text: FlowyText.medium(desc),
        rightIcon: icon,
        onTap: () {
          if (user.userId ==
              context.read<SettingsUserViewBloc>().userProfile.id) {
            return;
          }
          context
              .read<SettingsUserViewBloc>()
              .add(SettingsUserEvent.openHistoricalUser(user));
          didOpenUser();
        },
      ),
    );

    if (isSelected) {
      return child;
    } else {
      return Tooltip(
        message: LocaleKeys.settings_menu_openHistoricalUser.tr(),
        child: child,
      );
    }
  }
}
