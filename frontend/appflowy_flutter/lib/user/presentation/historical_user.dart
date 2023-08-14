import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/historical_user_bloc.dart';
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
    return BlocProvider(
      create: (context) => HistoricalUserBloc()
        ..add(
          const HistoricalUserEvent.initial(),
        ),
      child: BlocBuilder<HistoricalUserBloc, HistoricalUserState>(
        builder: (context, state) {
          if (state.historicalUsers.isEmpty) {
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
                      final user = state.historicalUsers[index];
                      return HistoricalUserItem(
                        key: ValueKey(user.userId),
                        user: user,
                        isSelected: false,
                        didOpenUser: didOpenUser,
                      );
                    },
                    itemCount: state.historicalUsers.length,
                  ),
                )
              ],
            );
          }
        },
      ),
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
    final outputFormat = DateFormat('MM/dd/yyyy hh:mm a');
    final date =
        DateTime.fromMillisecondsSinceEpoch(user.lastTime.toInt() * 1000);
    final lastTime = outputFormat.format(date);
    final desc = "${user.userName}\t ${user.authType}\t$lastTime";
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
          context
              .read<HistoricalUserBloc>()
              .add(HistoricalUserEvent.openHistoricalUser(user));
          didOpenUser();
        },
      ),
    );
    return child;
  }
}
