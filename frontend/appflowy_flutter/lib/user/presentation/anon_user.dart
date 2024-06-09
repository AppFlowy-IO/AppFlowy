import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/anon_user_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnonUserList extends StatelessWidget {
  const AnonUserList({required this.didOpenUser, super.key});

  final VoidCallback didOpenUser;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnonUserBloc()
        ..add(
          const AnonUserEvent.initial(),
        ),
      child: BlocBuilder<AnonUserBloc, AnonUserState>(
        builder: (context, state) {
          if (state.anonUsers.isEmpty) {
            return const SizedBox.shrink();
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: 0.6,
                  child: FlowyText.regular(
                    LocaleKeys.settings_menu_historicalUserListTooltip.tr(),
                    fontSize: 13,
                    maxLines: null,
                  ),
                ),
                const VSpace(6),
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      final user = state.anonUsers[index];
                      return AnonUserItem(
                        key: ValueKey(user.id),
                        user: user,
                        isSelected: false,
                        didOpenUser: didOpenUser,
                      );
                    },
                    itemCount: state.anonUsers.length,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class AnonUserItem extends StatelessWidget {
  const AnonUserItem({
    super.key,
    required this.user,
    required this.isSelected,
    required this.didOpenUser,
  });

  final UserProfilePB user;
  final bool isSelected;
  final VoidCallback didOpenUser;

  @override
  Widget build(BuildContext context) {
    final icon = isSelected ? const FlowySvg(FlowySvgs.check_s) : null;
    final isDisabled =
        isSelected || user.authenticator != AuthenticatorPB.Local;
    final desc = "${user.name}\t ${user.authenticator}\t";
    final child = SizedBox(
      height: 30,
      child: FlowyButton(
        disable: isDisabled,
        text: FlowyText.medium(
          desc,
          fontSize: 12,
        ),
        rightIcon: icon,
        onTap: () {
          context.read<AnonUserBloc>().add(AnonUserEvent.openAnonUser(user));
          didOpenUser();
        },
      ),
    );
    return child;
  }
}
